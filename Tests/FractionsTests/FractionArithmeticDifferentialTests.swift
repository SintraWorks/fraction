//
//  FractionArithmeticDifferentialTests.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Randomised tests pinning down every arithmetic result, sign placement included, against an
//  exact reference: each operation must return its result whenever that fits, and must refuse
//  whenever it does not. See License.md for the license text.

import XCTest
@testable import Fractions

// MARK: - Exact reference

/// A numerator and denominator in `Int128`, wide enough for anything the operations below form
/// from operands of up to 64 bits, so the reference itself never overflows.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct Exact {
    var numerator: Int128
    var denominator: Int128

    /// Reduced over magnitudes, each sign left where it was written, as `reduce()` does it.
    var reduced: Exact {
        var u = numerator.magnitude
        var v = denominator.magnitude
        while v != 0 {
            (v, u) = (u % v, v)
        }
        guard u != 0 else { return self }
        return Exact(numerator: numerator / Int128(u), denominator: denominator / Int128(u))
    }

    /// The fraction of `Integer` with these fields, or `nil` if either lies outside
    /// `Integer.min + 1 ... Integer.max`.
    func fraction<Integer>(of _: Integer.Type) -> Rational<Integer>? {
        let limit = UInt128(Integer.max)
        guard numerator.magnitude <= limit, denominator.magnitude <= limit else { return nil }
        return Rational(uncheckedNumerator: Integer(numerator), denominator: Integer(denominator))
    }
}

/// The arithmetic 1.2.0 shipped, spelling each result exactly as it did, but evaluated in `Int128`.
///
/// Wherever 1.2.0 did not trap, this is what it returned, so checking against it also checks that
/// none of those results has changed. An integer operand is written `i/1`, which reproduces how the
/// integer overloads spelled their results.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private enum Shipped {
    /// `add`, which normalized both operands first.
    static func sum<Integer>(_ x: Rational<Integer>, _ y: Rational<Integer>) -> Exact {
        let (a, b) = normalizedFields(x)
        let (c, d) = normalizedFields(y)
        return b == d ? Exact(numerator: a + c, denominator: b) : Exact(numerator: a * d + c * b, denominator: b * d)
    }

    /// `subtract`, which did not normalize.
    static func difference<Integer>(_ x: Rational<Integer>, _ y: Rational<Integer>) -> Exact {
        let (a, b) = (Int128(x.numerator), Int128(x.denominator))
        let (c, d) = (Int128(y.numerator), Int128(y.denominator))
        return b == d ? Exact(numerator: a - c, denominator: b) : Exact(numerator: a * d - c * b, denominator: b * d)
    }

    static func product<Integer>(_ x: Rational<Integer>, _ y: Rational<Integer>) -> Exact {
        Exact(numerator: Int128(x.numerator) * Int128(y.numerator),
              denominator: Int128(x.denominator) * Int128(y.denominator))
    }

    /// `divide` and `nonZeroDivide`.
    static func quotient<Integer>(_ x: Rational<Integer>, _ y: Rational<Integer>) -> Exact {
        Exact(numerator: Int128(x.numerator) * Int128(y.denominator),
              denominator: Int128(x.denominator) * Int128(y.numerator))
    }

    private static func normalizedFields<Integer>(_ fraction: Rational<Integer>) -> (Int128, Int128) {
        let (numerator, denominator) = (Int128(fraction.numerator), Int128(fraction.denominator))
        return denominator < 0 ? (-numerator, -denominator) : (numerator, denominator)
    }
}

// MARK: - Operations under test

/// One arithmetic operation, three ways: as 1.2.0 spelled its result, through the public API, and
/// through the function that API wraps, which returns `nil` wherever the API would trap.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct Operation<Integer: FixedWidthInteger & SignedInteger & Sendable> {
    var name: String
    var shipped: (Rational<Integer>, Rational<Integer>) -> Exact
    var api: (Rational<Integer>, Rational<Integer>, Bool) -> Rational<Integer>
    var core: (Rational<Integer>, Rational<Integer>, Bool) -> Rational<Integer>?
    /// The operators always reduce, so they have no unreduced result to check.
    var alwaysReduces = false
}

/// Fields compared as written, not as values: sign placement is part of what is pinned down.
func sameFields<Integer>(_ lhs: Rational<Integer>?, _ rhs: Rational<Integer>?) -> Bool {
    lhs?.numerator == rhs?.numerator && lhs?.denominator == rhs?.denominator
}

func describe<Integer>(_ fraction: Rational<Integer>?) -> String {
    fraction.map { $0.description } ?? "nil"
}

/// What a run of checks found.
struct Tally {
    var cases = 0
    var mismatches = 0
    var firstMismatch: String?
    /// Results that fit although 1.2.0's unreduced spelling of them did not, so 1.2.0 trapped.
    var rescued = 0
    /// Results that do not fit at all.
    var refused = 0

    mutating func record(mismatch description: @autoclosure () -> String) {
        mismatches += 1
        if firstMismatch == nil { firstMismatch = description() }
    }
}

@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
extension Tally {
    fileprivate mutating func check<Integer>(_ operation: Operation<Integer>,
                                             on pairs: [(Rational<Integer>, Rational<Integer>)]) {
        for reducing in operation.alwaysReduces ? [true] : [true, false] {
            for (x, y) in pairs {
                let spelled = operation.shipped(x, y)
                let expected = (reducing ? spelled.reduced : spelled).fraction(of: Integer.self)
                cases += 1
                if expected == nil {
                    refused += 1
                } else if spelled.fraction(of: Integer.self) == nil {
                    rescued += 1
                }

                // The API traps wherever its core returns nil, so it only runs where the core found
                // a result. A core wrongly refusing one is then a mismatch, not a crash.
                let fromCore = operation.core(x, y, reducing)
                let fromAPI = fromCore == nil ? nil : operation.api(x, y, reducing)
                if !sameFields(fromCore, expected) || !sameFields(fromAPI, expected) {
                    record(mismatch: "\(operation.name) on \(Integer.self) of \(x) and \(y), reducing: \(reducing), "
                        + "should be \(describe(expected)), got \(describe(fromCore)) from the core and \(describe(fromAPI)) from the API")
                }
            }
        }
    }
}

// MARK: - Inputs

extension SplitMix64 {
    /// A magnitude in `1 ... Integer.max`, from a regime that stresses one path or another:
    /// small values, arbitrary bit lengths, small multiples of powers of two, values just below
    /// `Integer.max`, and large fractions of it.
    mutating func nextEdgeMagnitude<Integer: FixedWidthInteger & SignedInteger>(_: Integer.Type) -> Integer {
        let bits = Integer.bitWidth - 1
        switch Int.random(in: 0 ..< 5, using: &self) {
        case 0:
            return Integer.random(in: 1 ... Integer(clamping: 4096), using: &self)
        case 1:
            let length = Int.random(in: 1 ... bits, using: &self)
            let lowest: Integer = length == 1 ? 1 : 1 << (length - 1)
            let highest: Integer = length == bits ? Integer.max : (1 << length) - 1
            return Integer.random(in: lowest ... highest, using: &self)
        case 2:
            // Factors below 2^7, so the shift can never carry one past `Integer.max`.
            return Integer.random(in: 1 ... Integer(clamping: 64), using: &self) << Int.random(in: 0 ... Swift.max(0, bits - 7), using: &self)
        case 3:
            return Integer.max - Integer.random(in: 0 ... Swift.min(Integer(clamping: 1000), Integer.max - 1), using: &self)
        default:
            return Integer.max / Integer.random(in: 1 ... Integer(clamping: 1000), using: &self)
        }
    }

    /// A fraction with fields near the edges of `Integer`, in all four sign combinations, with a
    /// zero numerator now and then, and a quarter of them left unreduced by a shared factor.
    mutating func nextEdgeFraction<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type) -> Rational<Integer> {
        var numerator: Integer = Int.random(in: 0 ..< 16, using: &self) == 0 ? 0 : nextEdgeMagnitude(Integer.self)
        var denominator: Integer = nextEdgeMagnitude(Integer.self)

        if Int.random(in: 0 ..< 4, using: &self) == 0 {
            let factor: Integer = Bool.random(using: &self)
                ? Integer.random(in: 2 ... Integer(clamping: 16), using: &self)
                : 1 << Int.random(in: 1 ... Swift.max(1, Integer.bitWidth - 24), using: &self)
            let (scaledNumerator, numeratorOverflow) = numerator.multipliedReportingOverflow(by: factor)
            let (scaledDenominator, denominatorOverflow) = denominator.multipliedReportingOverflow(by: factor)
            if !numeratorOverflow && !denominatorOverflow {
                (numerator, denominator) = (scaledNumerator, scaledDenominator)
            }
        }

        if Bool.random(using: &self) { numerator = -numerator }
        if Bool.random(using: &self) { denominator = -denominator }
        return Rational(verifiedNumerator: numerator, verifiedDenominator: denominator)
    }

    /// An integer operand, written `i/1`: any `Integer`, `Integer.min` and zero included.
    mutating func nextEdgeInteger<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type) -> Rational<Integer> {
        let integer: Integer
        switch Int.random(in: 0 ..< 8, using: &self) {
        case 0: integer = Integer.min
        case 1: integer = 0
        case 2: integer = [1, -1, 2, -2].randomElement(using: &self)!
        default: integer = Bool.random(using: &self) ? nextEdgeMagnitude(Integer.self) : -nextEdgeMagnitude(Integer.self)
        }
        return Rational(uncheckedNumerator: integer, denominator: 1)
    }

    /// Two fractions, some of them sharing a denominator as written, equal, or opposite, which
    /// are the cases with paths of their own.
    mutating func nextEdgePair<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type) -> (Rational<Integer>, Rational<Integer>) {
        let x = nextEdgeFraction(Integer.self)
        switch Int.random(in: 0 ..< 8, using: &self) {
        case 0: return (x, Rational(verifiedNumerator: nextEdgeFraction(Integer.self).numerator, verifiedDenominator: x.denominator))
        case 1: return (x, x)
        case 2: return (x, Rational(verifiedNumerator: -x.numerator, verifiedDenominator: x.denominator))
        default: return (x, nextEdgeFraction(Integer.self))
        }
    }

    /// Pairs of fractions, fractions with integers, and integers with fractions.
    mutating func nextEdgeCorpora<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type, count: Int)
        -> (fractions: [(Rational<Integer>, Rational<Integer>)], integers: [(Rational<Integer>, Rational<Integer>)],
            integersFirst: [(Rational<Integer>, Rational<Integer>)]) {
        ((0 ..< count).map { _ in nextEdgePair(Integer.self) },
         (0 ..< count).map { _ in (nextEdgeFraction(Integer.self), nextEdgeInteger(Integer.self)) },
         (0 ..< count).map { _ in (nextEdgeInteger(Integer.self), nextEdgeFraction(Integer.self)) })
    }
}

// MARK: - Tests

/// Arithmetic, checked by property rather than by example, at every width the reference covers.
///
/// The exact path is the same generic code at every width, and at 8 and 16 bits nearly every
/// operation reaches an edge, so the narrow runs stress it far more densely than `Int` can.
/// `Fraction128`, which is beyond an `Int128` reference, is checked in its own tests.
class FractionArithmeticDifferentialTests: XCTestCase {
    /// Pairs per corpus: plenty at `Int`, and enough at the narrow widths, where edges are dense.
    private static func pairCount<Integer: FixedWidthInteger>(_: Integer.Type) -> Int {
        Integer.bitWidth == 64 ? 40_000 : 10_000
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func assertAgrees<Integer>(_ tally: Tally, _: Integer.Type, seed: UInt64,
                                       file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(tally.mismatches, 0, """
            Disagrees with the exact reference on \(tally.mismatches) of \(tally.cases) cases for \(Integer.self) \
            (seed \(seed)). First: \(tally.firstMismatch ?? "none")
            """, file: file, line: line)
        // The corpus exists to reach the exact path and the refusals; make sure it still does.
        XCTAssertGreaterThan(tally.rescued, tally.cases / 100,
                             "Too few results that used to trap to exercise the exact path for \(Integer.self)", file: file, line: line)
        XCTAssertGreaterThan(tally.refused, tally.cases / 100,
                             "Too few results that do not fit to exercise refusing them for \(Integer.self)", file: file, line: line)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func checkAddition<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type, seed: UInt64) {
        var generator = SplitMix64(seed: seed)
        let corpus = generator.nextEdgeCorpora(Integer.self, count: Self.pairCount(Integer.self))
        var tally = Tally()

        tally.check(Operation<Integer>(name: "add",
                                       shipped: Shipped.sum,
                                       api: { $0.adding($1, reducing: $2) },
                                       core: { Rational.sum($0.normalized(), $1.normalized(), subtracting: false, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation<Integer>(name: "add(integer)",
                                       shipped: Shipped.sum,
                                       api: { $0.adding($1.numerator, reducing: $2) },
                                       core: { Rational.sum($0.normalized(), $1, subtracting: false, reducing: $2) }),
                    on: corpus.integers)
        tally.check(Operation<Integer>(name: "integer + fraction",
                                       shipped: { Shipped.sum($1, $0) },
                                       api: { a, b, _ in a.numerator + b },
                                       core: { Rational.sum($1.normalized(), $0, subtracting: false, reducing: $2) },
                                       alwaysReduces: true),
                    on: corpus.integersFirst)

        assertAgrees(tally, Integer.self, seed: seed)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func checkSubtraction<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type, seed: UInt64) {
        var generator = SplitMix64(seed: seed)
        let corpus = generator.nextEdgeCorpora(Integer.self, count: Self.pairCount(Integer.self))
        var tally = Tally()

        tally.check(Operation<Integer>(name: "subtract",
                                       shipped: Shipped.difference,
                                       api: { $0.subtracting($1, reducing: $2) },
                                       core: { Rational.sum($0, $1, subtracting: true, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation<Integer>(name: "subtract(integer)",
                                       shipped: Shipped.difference,
                                       api: { $0.subtracting($1.numerator, reducing: $2) },
                                       core: { Rational.sum($0, $1, subtracting: true, reducing: $2) }),
                    on: corpus.integers)
        tally.check(Operation<Integer>(name: "integer - fraction",
                                       shipped: Shipped.difference,
                                       api: { a, b, _ in a.numerator - b },
                                       core: { Rational.sum($0, $1, subtracting: true, reducing: $2) },
                                       alwaysReduces: true),
                    on: corpus.integersFirst)

        assertAgrees(tally, Integer.self, seed: seed)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func checkMultiplication<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type, seed: UInt64) {
        var generator = SplitMix64(seed: seed)
        let corpus = generator.nextEdgeCorpora(Integer.self, count: Self.pairCount(Integer.self))
        var tally = Tally()

        tally.check(Operation<Integer>(name: "multiply",
                                       shipped: Shipped.product,
                                       api: { $0.multiplying(by: $1, reducing: $2) },
                                       core: { Rational.product($0, $1, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation<Integer>(name: "multiply(integer)",
                                       shipped: Shipped.product,
                                       api: { $0.multiplying(by: $1.numerator, reducing: $2) },
                                       core: { Rational.product($0, $1, reducing: $2) }),
                    on: corpus.integers)
        tally.check(Operation<Integer>(name: "integer * fraction",
                                       shipped: { Shipped.product($1, $0) },
                                       api: { a, b, _ in a.numerator * b },
                                       core: { Rational.product($1, $0, reducing: $2) },
                                       alwaysReduces: true),
                    on: corpus.integersFirst)

        assertAgrees(tally, Integer.self, seed: seed)
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func checkDivision<Integer: FixedWidthInteger & SignedInteger & Sendable>(_: Integer.Type, seed: UInt64) {
        var generator = SplitMix64(seed: seed)
        let corpus = generator.nextEdgeCorpora(Integer.self, count: Self.pairCount(Integer.self))
        // Dividing by zero throws, or, through nonZeroDivide, is the caller's to avoid.
        let fractions = corpus.fractions.filter { $0.1.numerator != 0 }
        let integers = corpus.integers.filter { $0.1.numerator != 0 }
        let integersFirst = corpus.integersFirst.filter { $0.1.numerator != 0 }
        let reciprocal = { (fraction: Rational<Integer>) in
            Rational(uncheckedNumerator: fraction.denominator, denominator: fraction.numerator)
        }
        var tally = Tally()

        tally.check(Operation<Integer>(name: "divide",
                                       shipped: Shipped.quotient,
                                       api: { try! $0.dividing(by: $1, reducing: $2) },
                                       core: { Rational.product($0, reciprocal($1), reducing: $2) }),
                    on: fractions)
        tally.check(Operation<Integer>(name: "nonZeroDivide",
                                       shipped: Shipped.quotient,
                                       api: { $0.nonZeroDividing(by: $1, reducing: $2) },
                                       core: { Rational.product($0, reciprocal($1), reducing: $2) }),
                    on: fractions)
        tally.check(Operation<Integer>(name: "divide(integer)",
                                       shipped: Shipped.quotient,
                                       api: { try! $0.dividing(by: $1.numerator, reducing: $2) },
                                       core: { Rational.product($0, reciprocal($1), reducing: $2) }),
                    on: integers)
        tally.check(Operation<Integer>(name: "nonZeroDivide(integer)",
                                       shipped: Shipped.quotient,
                                       api: { $0.nonZeroDividing(by: $1.numerator, reducing: $2) },
                                       core: { Rational.product($0, reciprocal($1), reducing: $2) }),
                    on: integers)
        tally.check(Operation<Integer>(name: "integer / fraction",
                                       shipped: Shipped.quotient,
                                       api: { a, b, _ in try! a.numerator / b },
                                       core: { Rational.product($0, reciprocal($1), reducing: $2) },
                                       alwaysReduces: true),
                    on: integersFirst)

        assertAgrees(tally, Integer.self, seed: seed)
    }

    func testAdditionMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        checkAddition(Int.self, seed: 0x5EED_0000_0000_0010)
        checkAddition(Int32.self, seed: 0x5EED_0000_0000_0110)
        checkAddition(Int16.self, seed: 0x5EED_0000_0000_0210)
        checkAddition(Int8.self, seed: 0x5EED_0000_0000_0310)
    }

    func testSubtractionMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        checkSubtraction(Int.self, seed: 0x5EED_0000_0000_0011)
        checkSubtraction(Int32.self, seed: 0x5EED_0000_0000_0111)
        checkSubtraction(Int16.self, seed: 0x5EED_0000_0000_0211)
        checkSubtraction(Int8.self, seed: 0x5EED_0000_0000_0311)
    }

    func testMultiplicationMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        checkMultiplication(Int.self, seed: 0x5EED_0000_0000_0012)
        checkMultiplication(Int32.self, seed: 0x5EED_0000_0000_0112)
        checkMultiplication(Int16.self, seed: 0x5EED_0000_0000_0212)
        checkMultiplication(Int8.self, seed: 0x5EED_0000_0000_0312)
    }

    func testDivisionMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        checkDivision(Int.self, seed: 0x5EED_0000_0000_0013)
        checkDivision(Int32.self, seed: 0x5EED_0000_0000_0113)
        checkDivision(Int16.self, seed: 0x5EED_0000_0000_0213)
        checkDivision(Int8.self, seed: 0x5EED_0000_0000_0313)
    }
}
