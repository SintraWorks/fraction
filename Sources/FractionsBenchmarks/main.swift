//
//  main.swift
//  FractionsBenchmarks
//
//  A dependency-free benchmark for the operations on Fraction's hot path.
//
//  Run it in release; a debug build measures the optimizer's absence, not the code:
//
//      swift run -c release FractionsBenchmarks
//      swift run -c release -Xswiftc -cross-module-optimization FractionsBenchmarks
//
//  The benchmark imports Fractions as a dependent does. SwiftPM does not enable cross-module
//  optimization by default, so a dependent sees only what is `@inlinable`; the hot paths are,
//  because `Rational` is generic, and generic code a caller cannot see runs unspecialized and many
//  times slower. The second invocation shows what cross-module optimization adds on top.
//
//  - Important: This target must never gain a package dependency. The root manifest has an
//    empty dependency graph, and anything added here would enter every dependent's
//    `Package.resolved`. If a benchmark library is ever needed, move this into a nested
//    package with its own manifest.

import Fractions

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// MARK: - Deterministic input

/// SplitMix64. Seeded, so every run measures the same data.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

// MARK: - Measurement

/// Keeps the optimizer from deleting the work whose cost we are trying to observe.
@inline(never)
func blackHole<T>(_ value: T) { withExtendedLifetime(value) {} }

/// A monotonic clock. `ContinuousClock` would be tidier but needs macOS 13, and this package
/// declares no deployment target — adding one to the root manifest would raise the floor for
/// every dependent, which is not a change a benchmark gets to make.
func monotonicNanoseconds() -> Double {
    var time = timespec()
    clock_gettime(CLOCK_MONOTONIC, &time)
    return Double(time.tv_sec) * 1e9 + Double(time.tv_nsec)
}

/// Right-pads to `width` characters.
func padded(_ text: String, to width: Int) -> String {
    text.count >= width ? text : text + String(repeating: " ", count: width - text.count)
}

/// Left-pads a value rounded to two decimals.
func padded(_ value: Double, to width: Int) -> String {
    let rounded = (value * 100).rounded() / 100
    var text = "\(rounded)"
    // "\(Double)" prints at least one fraction digit, so this only ever appends one.
    if text.hasSuffix(".0") { text += "0" }
    return text.count >= width ? text : String(repeating: " ", count: width - text.count) + text
}

/// Reports the best of `rounds` runs. `setup` is excluded from the timing, which matters for
/// the sort: refilling the array is a 5.6 MB memcpy that would otherwise be measured too.
func measure(
    _ name: String,
    operations: Int,
    rounds: Int = 7,
    setup: () -> Void = {},
    _ body: (Int) -> Void
) {
    var best = Double.infinity
    for round in 0 ..< rounds {
        setup()
        let start = monotonicNanoseconds()
        body(round)
        best = Swift.min(best, monotonicNanoseconds() - start)
    }
    print("\(padded(name, to: 32))\(padded(best / 1e6, to: 10)) ms  \(padded(best / Double(operations), to: 9)) ns/op")
}

// MARK: - Corpus

let count = 350_000
var generator = SplitMix64(seed: 0xC0FF_EE12_3456_789A)

/// Denominators in the low thousands, all four sign combinations, as the brief describes.
let corpus: [Fraction] = (0 ..< count).map { _ in
    let numerator = Int.random(in: 1 ... 4096, using: &generator)
    let denominator = Int.random(in: 1 ... 4096, using: &generator)
    let negativeNumerator = Bool.random(using: &generator)
    let negativeDenominator = Bool.random(using: &generator)
    return Fraction(verifiedNumerator: negativeNumerator ? -numerator : numerator,
                    verifiedDenominator: negativeDenominator ? -denominator : denominator)
}

/// The control. Two Ints with a synthesized Hashable, so `Set<IntPair>` measures the floor that
/// `Hasher` and `Set` impose on `Set<Fraction>`. Anything below this line is not addressable by
/// making `hash(into:)` cheaper.
struct IntPair: Hashable {
    var numerator: Int
    var denominator: Int
}

let controlCorpus = corpus.map { IntPair(numerator: $0.numerator, denominator: $0.denominator) }

/// Every element of `corpus`, rewritten in a different but equal form. Comparing the two arrays
/// element-wise gives `==` a corpus it cannot answer trivially — every pair is equal, but only
/// after cross-multiplication — and keeps the optimizer from folding the loop away, which it does
/// when the answer is "false" for essentially every pair.
let equalCorpus: [Fraction] = corpus.map { fraction in
    let largestField = Swift.max(fraction.numerator.magnitude, fraction.denominator.magnitude)
    let scale = Int(UInt(Int.max) / Swift.max(largestField, 1)) > 3 ? 3 : 1
    return Fraction(verifiedNumerator: fraction.numerator * scale,
                    verifiedDenominator: fraction.denominator * scale)
}

/// Fractions whose sums all take the exact path: power-of-two denominators of 2^32 and up, so
/// the fast path's product of two of them overflows, while every sum fits once reduced. Odd
/// numerators keep each fraction in lowest terms.
let exactPathCorpus: [Fraction] = (0 ..< count).map { _ in
    let numerator = Int.random(in: 1 ... 4096, using: &generator) | 1
    let exponent = Int.random(in: 32 ... 62, using: &generator)
    return Fraction(verifiedNumerator: Bool.random(using: &generator) ? -numerator : numerator,
                    verifiedDenominator: 1 << exponent)
}

// MARK: - Scans
//
// Each scan is `@inline(never)` and takes the round number as its starting index. Without that,
// the optimizer notices that a scan over immutable global arrays computes the same answer on
// every one of the seven rounds, hoists it out of the timing loop, and reports 0.00 ms. A
// per-round argument makes the seven calls genuinely different, so each one has to run.

@inline(never)
func reductionScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count {
        checksum = checksum &+ fractions[index].reduced().normalized().numerator
    }
    return checksum
}

/// A running minimum: the loop-carried dependency on `smallest` also stops the comparisons being
/// vectorized, so this is one real comparison per element.
@inline(never)
func orderingScan(_ fractions: [Fraction], from start: Int) -> Fraction {
    var smallest = fractions[start]
    for index in (start + 1) ..< fractions.count where fractions[index] < smallest {
        smallest = fractions[index]
    }
    return smallest
}

/// Every pair compared here is equal but differently spelled — the case `==` exists to get right,
/// and the one that cannot be answered without doing the work.
@inline(never)
func equalityScan(_ fractions: [Fraction], _ equalForms: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count where fractions[index] == equalForms[index] {
        checksum = checksum &+ 1
    }
    return checksum
}

@inline(never)
func hashScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count {
        checksum = checksum &+ fractions[index].hashValue
    }
    return checksum
}

/// The control for `hashScan`: whatever this costs is `Hasher` itself, and no amount of work on
/// `hash(into:)` can go below it.
@inline(never)
func controlHashScan(_ pairs: [IntPair], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< pairs.count {
        checksum = checksum &+ pairs[index].hashValue
    }
    return checksum
}

// The arithmetic scans combine each element with its successor. Every operand is in the low
// thousands, so no product comes near overflowing: these measure the path arithmetic takes in
// ordinary use, reduction included.

@inline(never)
func additionScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count - 1 {
        checksum = checksum &+ (fractions[index] + fractions[index + 1]).denominator
    }
    return checksum
}

@inline(never)
func integerAdditionScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count - 1 {
        checksum = checksum &+ (fractions[index] + fractions[index + 1].numerator).denominator
    }
    return checksum
}

@inline(never)
func subtractionScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count - 1 {
        checksum = checksum &+ (fractions[index] - fractions[index + 1]).denominator
    }
    return checksum
}

@inline(never)
func multiplicationScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count - 1 {
        checksum = checksum &+ (fractions[index] * fractions[index + 1]).denominator
    }
    return checksum
}

/// The corpus has no zero numerators, so no division here throws.
@inline(never)
func divisionScan(_ fractions: [Fraction], from start: Int) -> Int {
    var checksum = 0
    for index in start ..< fractions.count - 1 {
        checksum = checksum &+ (try! fractions[index] / fractions[index + 1]).denominator
    }
    return checksum
}

// MARK: - Run

#if DEBUG
print("configuration: DEBUG (measures the optimizer's absence \u{2014} compare release numbers only)")
#else
print("configuration: RELEASE")
#endif
print("elements:      \(count)")
print("")

// A sort of n elements runs on the order of n\u{00B7}log2(n) comparisons. The per-op column below
// divides by that estimate, so read it as an order of magnitude, not an exact unit cost.
let integerLog2 = count.bitWidth - 1 - count.leadingZeroBitCount
let sortComparisons = count * integerLog2

var work = [Fraction](repeating: .zero, count: count)

measure("sort (~n log n comparisons)", operations: sortComparisons, setup: {
    // withUnsafeMutableBufferPointer forces uniqueness here rather than inside the timed body,
    // so the 5.6 MB refill is not measured as part of the sort.
    work.withUnsafeMutableBufferPointer { buffer in
        for index in 0 ..< count { buffer[index] = corpus[index] }
    }
}) { _ in
    work.sort()
    blackHole(work[count / 2])
}

measure("Set<Fraction> insert", operations: count) { _ in
    var set = Set<Fraction>(minimumCapacity: count)
    for fraction in corpus { set.insert(fraction) }
    blackHole(set.count)
}

measure("Set<IntPair> insert (control)", operations: count) { _ in
    var set = Set<IntPair>(minimumCapacity: count)
    for pair in controlCorpus { set.insert(pair) }
    blackHole(set.count)
}

measure("reduced().normalized()", operations: count) { round in
    blackHole(reductionScan(corpus, from: round))
}

measure("< (running minimum)", operations: count) { round in
    blackHole(orderingScan(corpus, from: round))
}

measure("== (equal, unequal forms)", operations: count) { round in
    blackHole(equalityScan(corpus, equalCorpus, from: round))
}

measure("hashValue", operations: count) { round in
    blackHole(hashScan(corpus, from: round))
}

measure("hashValue (control)", operations: count) { round in
    blackHole(controlHashScan(controlCorpus, from: round))
}

measure("+", operations: count) { round in
    blackHole(additionScan(corpus, from: round))
}

measure("+ (exact path)", operations: count) { round in
    blackHole(additionScan(exactPathCorpus, from: round))
}

measure("+ Int", operations: count) { round in
    blackHole(integerAdditionScan(corpus, from: round))
}

measure("-", operations: count) { round in
    blackHole(subtractionScan(corpus, from: round))
}

measure("*", operations: count) { round in
    blackHole(multiplicationScan(corpus, from: round))
}

measure("/", operations: count) { round in
    blackHole(divisionScan(corpus, from: round))
}
