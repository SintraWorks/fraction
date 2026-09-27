//
//  Fraction128DifferentialTests.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Randomised tests for Fraction128 arithmetic across the full 128-bit range. Products of two
//  Int128 fields need 256 bits, beyond any integer type Swift has, so the reference here is a
//  256-bit checker built to depend on nothing the library does. See License.md for the license
//  text.

import XCTest
@testable import Fractions

// MARK: - A 256-bit checker

/// An unsigned integer of 256 bits, as two `UInt128` halves: enough for any product of two
/// `Int128` fields and any sum of two such products.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct Wide: Comparable {
    var high: UInt128
    var low: UInt128

    init(high: UInt128 = 0, low: UInt128) {
        self.high = high
        self.low = low
    }

    /// The full product of two 128-bit magnitudes.
    init(product a: UInt128, _ b: UInt128) {
        let (high, low) = a.multipliedFullWidth(by: b)
        self.init(high: high, low: low)
    }

    var isZero: Bool { high == 0 && low == 0 }

    static func < (a: Wide, b: Wide) -> Bool {
        (a.high, a.low) < (b.high, b.low)
    }

    /// `a + b`, or `nil` beyond 256 bits.
    static func adding(_ a: Wide, _ b: Wide) -> Wide? {
        let (low, carry) = a.low.addingReportingOverflow(b.low)
        let (partial, firstOverflow) = a.high.addingReportingOverflow(b.high)
        let (high, secondOverflow) = partial.addingReportingOverflow(carry ? 1 : 0)
        return firstOverflow || secondOverflow ? nil : Wide(high: high, low: low)
    }

    /// `a - b`, for `a >= b`.
    static func - (a: Wide, b: Wide) -> Wide {
        let (low, borrow) = a.low.subtractingReportingOverflow(b.low)
        return Wide(high: a.high - b.high - (borrow ? 1 : 0), low: low)
    }

    /// `self · factor`, or `nil` beyond 256 bits.
    func multiplied(by factor: UInt128) -> Wide? {
        let (highProduct, highOverflow) = high.multipliedReportingOverflow(by: factor)
        guard !highOverflow else { return nil }
        return Wide.adding(Wide(product: low, factor), Wide(high: highProduct, low: 0))
    }

    var trailingZeroBitCount: Int {
        low != 0 ? low.trailingZeroBitCount : 128 + high.trailingZeroBitCount
    }

    static func >> (a: Wide, count: Int) -> Wide {
        guard count > 0 else { return a }
        guard count < 128 else { return Wide(low: a.high >> (count - 128)) }
        return Wide(high: a.high >> count, low: (a.low >> count) | (a.high << (128 - count)))
    }

    /// Only for values known to stay within 256 bits.
    static func << (a: Wide, count: Int) -> Wide {
        guard count > 0 else { return a }
        guard count < 128 else { return Wide(high: a.low << (count - 128), low: 0) }
        return Wide(high: (a.high << count) | (a.low >> (128 - count)), low: a.low << count)
    }

    /// Stein's binary algorithm: shifts and subtractions, and none of the division the library's
    /// Euclid relies on.
    static func greatestCommonDivisor(_ a: Wide, _ b: Wide) -> Wide {
        if a.isZero { return b }
        if b.isZero { return a }
        let shift = Swift.min(a.trailingZeroBitCount, b.trailingZeroBitCount)
        var u = a >> a.trailingZeroBitCount
        var v = b
        repeat {
            v = v >> v.trailingZeroBitCount
            if v < u { swap(&u, &v) }
            v = v - u
        } while !v.isZero
        return u << shift
    }
}

/// A signed 256-bit value: the numerator or denominator an operation spells, before reducing.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct SignedWide {
    var isNegative: Bool
    var magnitude: Wide

    init(isNegative: Bool, magnitude: Wide) {
        // Zero has no sign.
        self.isNegative = isNegative && !magnitude.isZero
        self.magnitude = magnitude
    }

    init(_ value: Int128) {
        self.init(isNegative: value < 0, magnitude: Wide(low: value.magnitude))
    }

    static func product(_ a: Int128, _ b: Int128) -> SignedWide {
        SignedWide(isNegative: (a < 0) != (b < 0), magnitude: Wide(product: a.magnitude, b.magnitude))
    }

    /// Every term here is below 2^254, so no sum reaches 2^256.
    static func + (a: SignedWide, b: SignedWide) -> SignedWide {
        if a.isNegative == b.isNegative {
            return SignedWide(isNegative: a.isNegative, magnitude: Wide.adding(a.magnitude, b.magnitude)!)
        }
        return b.magnitude < a.magnitude
            ? SignedWide(isNegative: a.isNegative, magnitude: a.magnitude - b.magnitude)
            : SignedWide(isNegative: b.isNegative, magnitude: b.magnitude - a.magnitude)
    }

    static prefix func - (value: SignedWide) -> SignedWide {
        SignedWide(isNegative: !value.isNegative, magnitude: value.magnitude)
    }
}

/// The arithmetic 1.2.0 shipped, spelling each result as it did, evaluated at 256 bits.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private enum Spelled {
    typealias Result = (numerator: SignedWide, denominator: SignedWide)

    /// `add`, which normalized both operands first.
    static func sum(_ x: Fraction128, _ y: Fraction128) -> Result {
        let (x, y) = (x.normalized(), y.normalized())
        if x.denominator == y.denominator {
            return (SignedWide(x.numerator) + SignedWide(y.numerator), SignedWide(x.denominator))
        }
        return (SignedWide.product(x.numerator, y.denominator) + SignedWide.product(y.numerator, x.denominator),
                SignedWide.product(x.denominator, y.denominator))
    }

    /// `subtract`, which did not normalize.
    static func difference(_ x: Fraction128, _ y: Fraction128) -> Result {
        if x.denominator == y.denominator {
            return (SignedWide(x.numerator) + -SignedWide(y.numerator), SignedWide(x.denominator))
        }
        return (SignedWide.product(x.numerator, y.denominator) + -SignedWide.product(y.numerator, x.denominator),
                SignedWide.product(x.denominator, y.denominator))
    }

    static func product(_ x: Fraction128, _ y: Fraction128) -> Result {
        (SignedWide.product(x.numerator, y.numerator), SignedWide.product(x.denominator, y.denominator))
    }

    /// `divide` and `nonZeroDivide`.
    static func quotient(_ x: Fraction128, _ y: Fraction128) -> Result {
        (SignedWide.product(x.numerator, y.denominator), SignedWide.product(x.denominator, y.numerator))
    }

    /// `nil` when `result` is exactly what the spelled value calls for, and otherwise what is wrong.
    ///
    /// Unreduced, the result must be the spelled fields themselves, or `nil` if they do not fit.
    /// Reduced, with `g` the greatest common divisor of the spelled fields: a result must equal
    /// them divided by `g` — checked by multiplying back, which proves the value and lowest terms
    /// at once — with each sign where it was spelled; and a refusal must be of a value whose
    /// reduced fields, the spelled ones divided by `g`, exceed `Int128.max`.
    static func problem(with result: Fraction128?, for spelled: Result, reducing: Bool) -> String? {
        let limit = Wide(low: UInt128(Int128.max))
        let (numerator, denominator) = spelled

        guard reducing else {
            guard !(limit < numerator.magnitude), !(limit < denominator.magnitude) else {
                return result.map { "should not fit unreduced, got \($0)" }
            }
            let expected = Fraction128(uncheckedNumerator: signed(numerator), denominator: signed(denominator))
            return sameFields(result, expected) ? nil : "should be \(expected), got \(describe(result))"
        }

        let divisor = Wide.greatestCommonDivisor(numerator.magnitude, denominator.magnitude)
        // Beyond 256 bits, the bound is above every magnitude spelled here.
        let bound = divisor.multiplied(by: UInt128(Int128.max))
        let fits = bound.map { !($0 < numerator.magnitude) && !($0 < denominator.magnitude) } ?? true

        guard let result else { return fits ? "was refused, but its reduced form fits" : nil }
        guard fits else { return "should have been refused, got \(result)" }
        guard divisor.multiplied(by: result.numerator.magnitude) == numerator.magnitude,
              divisor.multiplied(by: result.denominator.magnitude) == denominator.magnitude
        else { return "got \(result), which is not the spelled value in lowest terms" }
        guard (result.denominator < 0) == denominator.isNegative,
              result.numerator == 0 || (result.numerator < 0) == numerator.isNegative
        else { return "got \(result), with a sign away from where it was spelled" }
        return nil
    }

    private static func signed(_ value: SignedWide) -> Int128 {
        value.isNegative ? -Int128(value.magnitude.low) : Int128(value.magnitude.low)
    }
}

/// One `Fraction128` operation: as 1.2.0 spelled its result, through the public API, and through
/// the function that API wraps, which returns `nil` wherever the API would trap.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct Operation128 {
    var name: String
    var spelled: (Fraction128, Fraction128) -> Spelled.Result
    var api: (Fraction128, Fraction128, Bool) -> Fraction128
    var core: (Fraction128, Fraction128, Bool) -> Fraction128?
    var alwaysReduces = false
}

@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
extension Tally {
    fileprivate mutating func check(_ operation: Operation128, on pairs: [(Fraction128, Fraction128)]) {
        let limit = Wide(low: UInt128(Int128.max))
        for reducing in operation.alwaysReduces ? [true] : [true, false] {
            for (x, y) in pairs {
                let spelled = operation.spelled(x, y)
                let fromCore = operation.core(x, y, reducing)
                cases += 1
                if fromCore == nil {
                    refused += 1
                } else if limit < spelled.numerator.magnitude || limit < spelled.denominator.magnitude {
                    rescued += 1
                }

                if let problem = Spelled.problem(with: fromCore, for: spelled, reducing: reducing) {
                    record(mismatch: "\(operation.name) of \(x) and \(y), reducing: \(reducing): \(problem)")
                } else if let fromCore {
                    // The API wraps the core, so wherever the core found a result, it must agree.
                    let fromAPI = operation.api(x, y, reducing)
                    if !sameFields(fromAPI, fromCore) {
                        record(mismatch: "\(operation.name) of \(x) and \(y), reducing: \(reducing): the API returned \(fromAPI), the core \(fromCore)")
                    }
                }
            }
        }
    }
}

// MARK: - Tests

/// `Fraction128` arithmetic, checked by property across the full 128-bit range.
class Fraction128DifferentialTests: XCTestCase {
    private static let pairCount = 3_000

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func corpora(seed: UInt64) -> (fractions: [(Fraction128, Fraction128)], integers: [(Fraction128, Fraction128)],
                                           integersFirst: [(Fraction128, Fraction128)]) {
        var generator = SplitMix64(seed: seed)
        return generator.nextEdgeCorpora(Int128.self, count: Self.pairCount)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func assertAgrees(_ tally: Tally, seed: UInt64, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(tally.mismatches, 0, """
            Disagrees with the 256-bit check on \(tally.mismatches) of \(tally.cases) cases (seed \(seed)). \
            First: \(tally.firstMismatch ?? "none")
            """, file: file, line: line)
        XCTAssertGreaterThan(tally.rescued, tally.cases / 100, "Too few results that need the exact path", file: file, line: line)
        XCTAssertGreaterThan(tally.refused, tally.cases / 100, "Too few results that do not fit", file: file, line: line)
    }

    func testAdditionAcrossTheFullRange() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip("Fraction128 needs Int128.") }
        let seed: UInt64 = 0x5EED_0000_0000_0410
        let corpus = corpora(seed: seed)
        var tally = Tally()

        tally.check(Operation128(name: "add", spelled: Spelled.sum,
                                 api: { $0.adding($1, reducing: $2) },
                                 core: { Fraction128.sum($0.normalized(), $1.normalized(), subtracting: false, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation128(name: "add(integer)", spelled: Spelled.sum,
                                 api: { $0.adding($1.numerator, reducing: $2) },
                                 core: { Fraction128.sum($0.normalized(), $1, subtracting: false, reducing: $2) }),
                    on: corpus.integers)
        assertAgrees(tally, seed: seed)
    }

    func testSubtractionAcrossTheFullRange() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip("Fraction128 needs Int128.") }
        let seed: UInt64 = 0x5EED_0000_0000_0411
        let corpus = corpora(seed: seed)
        var tally = Tally()

        tally.check(Operation128(name: "subtract", spelled: Spelled.difference,
                                 api: { $0.subtracting($1, reducing: $2) },
                                 core: { Fraction128.sum($0, $1, subtracting: true, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation128(name: "integer - fraction", spelled: Spelled.difference,
                                 api: { a, b, _ in a.numerator - b },
                                 core: { Fraction128.sum($0, $1, subtracting: true, reducing: $2) },
                                 alwaysReduces: true),
                    on: corpus.integersFirst)
        assertAgrees(tally, seed: seed)
    }

    func testMultiplicationAcrossTheFullRange() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip("Fraction128 needs Int128.") }
        let seed: UInt64 = 0x5EED_0000_0000_0412
        let corpus = corpora(seed: seed)
        var tally = Tally()

        tally.check(Operation128(name: "multiply", spelled: Spelled.product,
                                 api: { $0.multiplying(by: $1, reducing: $2) },
                                 core: { Fraction128.product($0, $1, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation128(name: "multiply(integer)", spelled: Spelled.product,
                                 api: { $0.multiplying(by: $1.numerator, reducing: $2) },
                                 core: { Fraction128.product($0, $1, reducing: $2) }),
                    on: corpus.integers)
        assertAgrees(tally, seed: seed)
    }

    func testDivisionAcrossTheFullRange() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip("Fraction128 needs Int128.") }
        let seed: UInt64 = 0x5EED_0000_0000_0413
        let corpus = corpora(seed: seed)
        let reciprocal = { (fraction: Fraction128) in
            Fraction128(uncheckedNumerator: fraction.denominator, denominator: fraction.numerator)
        }
        var tally = Tally()

        tally.check(Operation128(name: "divide", spelled: Spelled.quotient,
                                 api: { try! $0.dividing(by: $1, reducing: $2) },
                                 core: { Fraction128.product($0, reciprocal($1), reducing: $2) }),
                    on: corpus.fractions.filter { $0.1.numerator != 0 })
        tally.check(Operation128(name: "divide(integer)", spelled: Spelled.quotient,
                                 api: { try! $0.dividing(by: $1.numerator, reducing: $2) },
                                 core: { Fraction128.product($0, reciprocal($1), reducing: $2) }),
                    on: corpus.integers.filter { $0.1.numerator != 0 })
        assertAgrees(tally, seed: seed)
    }
}
