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
/// from `Int` operands, so the reference itself never overflows.
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

    /// The fraction with these fields, or `nil` if either lies outside `Int.min + 1 ... Int.max`.
    var fraction: Fraction? {
        guard numerator.magnitude <= UInt128(Int.max), denominator.magnitude <= UInt128(Int.max) else { return nil }
        return unchecked(Int(numerator), Int(denominator))
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
    static func sum(_ x: Fraction, _ y: Fraction) -> Exact {
        let (a, b) = normalizedFields(x)
        let (c, d) = normalizedFields(y)
        return b == d ? Exact(numerator: a + c, denominator: b) : Exact(numerator: a * d + c * b, denominator: b * d)
    }

    /// `subtract`, which did not normalize.
    static func difference(_ x: Fraction, _ y: Fraction) -> Exact {
        let (a, b) = (Int128(x.numerator), Int128(x.denominator))
        let (c, d) = (Int128(y.numerator), Int128(y.denominator))
        return b == d ? Exact(numerator: a - c, denominator: b) : Exact(numerator: a * d - c * b, denominator: b * d)
    }

    static func product(_ x: Fraction, _ y: Fraction) -> Exact {
        Exact(numerator: Int128(x.numerator) * Int128(y.numerator),
              denominator: Int128(x.denominator) * Int128(y.denominator))
    }

    /// `divide` and `nonZeroDivide`.
    static func quotient(_ x: Fraction, _ y: Fraction) -> Exact {
        Exact(numerator: Int128(x.numerator) * Int128(y.denominator),
              denominator: Int128(x.denominator) * Int128(y.numerator))
    }

    private static func normalizedFields(_ fraction: Fraction) -> (Int128, Int128) {
        let (numerator, denominator) = (Int128(fraction.numerator), Int128(fraction.denominator))
        return denominator < 0 ? (-numerator, -denominator) : (numerator, denominator)
    }
}

// MARK: - Operations under test

/// One arithmetic operation, three ways: as 1.2.0 spelled its result, through the public API, and
/// through the function that API wraps, which returns `nil` wherever the API would trap.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct Operation {
    var name: String
    var shipped: (Fraction, Fraction) -> Exact
    var api: (Fraction, Fraction, Bool) -> Fraction
    var core: (Fraction, Fraction, Bool) -> Fraction?
    /// The operators always reduce, so they have no unreduced result to check.
    var alwaysReduces = false
}

/// Fields compared as written, not as values: sign placement is part of what is pinned down.
private func sameFields(_ lhs: Fraction?, _ rhs: Fraction?) -> Bool {
    lhs?.numerator == rhs?.numerator && lhs?.denominator == rhs?.denominator
}

private func describe(_ fraction: Fraction?) -> String {
    fraction.map { $0.description } ?? "nil"
}

@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
private struct Tally {
    var cases = 0
    var mismatches = 0
    var firstMismatch: String?
    /// Results that fit although 1.2.0's unreduced spelling of them did not, so 1.2.0 trapped.
    var rescued = 0
    /// Results that do not fit at all.
    var refused = 0

    mutating func check(_ operation: Operation, on pairs: [(Fraction, Fraction)]) {
        for reducing in operation.alwaysReduces ? [true] : [true, false] {
            for (x, y) in pairs {
                let spelled = operation.shipped(x, y)
                let expected = (reducing ? spelled.reduced : spelled).fraction
                cases += 1
                if expected == nil {
                    refused += 1
                } else if spelled.fraction == nil {
                    rescued += 1
                }

                // The API traps wherever its core returns nil, so it only runs where the core found
                // a result. A core wrongly refusing one is then a mismatch, not a crash.
                let fromCore = operation.core(x, y, reducing)
                let fromAPI = fromCore == nil ? nil : operation.api(x, y, reducing)
                if !sameFields(fromCore, expected) || !sameFields(fromAPI, expected) {
                    mismatches += 1
                    if firstMismatch == nil {
                        firstMismatch = "\(operation.name) of \(x) and \(y), reducing: \(reducing), should be "
                            + "\(describe(expected)), got \(describe(fromCore)) from the core and \(describe(fromAPI)) from the API"
                    }
                }
            }
        }
    }
}

// MARK: - Inputs

extension SplitMix64 {
    /// A magnitude in `1 ... Int.max`, from a regime that stresses one path or another: small
    /// values, arbitrary bit lengths, small multiples of powers of two, values just below
    /// `Int.max`, and large fractions of it.
    mutating func nextEdgeMagnitude() -> Int {
        switch Int.random(in: 0 ..< 5, using: &self) {
        case 0:
            return Int.random(in: 1 ... 4096, using: &self)
        case 1:
            let bits = Int.random(in: 1 ... 63, using: &self)
            let lowest = bits == 1 ? 1 : 1 << (bits - 1)
            let highest = bits == 63 ? Int.max : (1 << bits) - 1
            return Int.random(in: lowest ... highest, using: &self)
        case 2:
            return Int.random(in: 1 ... 64, using: &self) << Int.random(in: 0 ... 56, using: &self)
        case 3:
            return Int.max - Int.random(in: 0 ... 1000, using: &self)
        default:
            return Int.max / Int.random(in: 1 ... 1000, using: &self)
        }
    }

    /// A fraction with fields near the edges of `Int`, in all four sign combinations, with a
    /// zero numerator now and then, and a quarter of them left unreduced by a shared factor.
    mutating func nextEdgeFraction() -> Fraction {
        var numerator = Int.random(in: 0 ..< 16, using: &self) == 0 ? 0 : nextEdgeMagnitude()
        var denominator = nextEdgeMagnitude()

        if Int.random(in: 0 ..< 4, using: &self) == 0 {
            let factor = Bool.random(using: &self)
                ? Int.random(in: 2 ... 16, using: &self)
                : 1 << Int.random(in: 1 ... 40, using: &self)
            let (scaledNumerator, numeratorOverflow) = numerator.multipliedReportingOverflow(by: factor)
            let (scaledDenominator, denominatorOverflow) = denominator.multipliedReportingOverflow(by: factor)
            if !numeratorOverflow && !denominatorOverflow {
                (numerator, denominator) = (scaledNumerator, scaledDenominator)
            }
        }

        if Bool.random(using: &self) { numerator = -numerator }
        if Bool.random(using: &self) { denominator = -denominator }
        return Fraction(verifiedNumerator: numerator, verifiedDenominator: denominator)
    }

    /// An integer operand, written `i/1`: any `Int`, `Int.min` and zero included.
    mutating func nextEdgeInteger() -> Fraction {
        let integer: Int
        switch Int.random(in: 0 ..< 8, using: &self) {
        case 0: integer = Int.min
        case 1: integer = 0
        case 2: integer = [1, -1, 2, -2].randomElement(using: &self)!
        default: integer = Bool.random(using: &self) ? nextEdgeMagnitude() : -nextEdgeMagnitude()
        }
        return unchecked(integer, 1)
    }

    /// Two fractions, some of them sharing a denominator as written, equal, or opposite, which
    /// are the cases with paths of their own.
    mutating func nextEdgePair() -> (Fraction, Fraction) {
        let x = nextEdgeFraction()
        switch Int.random(in: 0 ..< 8, using: &self) {
        case 0: return (x, Fraction(verifiedNumerator: nextEdgeFraction().numerator, verifiedDenominator: x.denominator))
        case 1: return (x, x)
        case 2: return (x, Fraction(verifiedNumerator: -x.numerator, verifiedDenominator: x.denominator))
        default: return (x, nextEdgeFraction())
        }
    }
}

// MARK: - Tests

/// Arithmetic, checked by property rather than by example.
class FractionArithmeticDifferentialTests: XCTestCase {
    private static let pairCount = 40_000

    /// Pairs of fractions, fractions with integers, and integers with fractions.
    private func corpora(seed: UInt64) -> (fractions: [(Fraction, Fraction)], integers: [(Fraction, Fraction)],
                                           integersFirst: [(Fraction, Fraction)]) {
        var generator = SplitMix64(seed: seed)
        let count = Self.pairCount
        return ((0 ..< count).map { _ in generator.nextEdgePair() },
                (0 ..< count).map { _ in (generator.nextEdgeFraction(), generator.nextEdgeInteger()) },
                (0 ..< count).map { _ in (generator.nextEdgeInteger(), generator.nextEdgeFraction()) })
    }

    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func assertAgrees(_ tally: Tally, seed: UInt64, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(tally.mismatches, 0, """
            Disagrees with the exact reference on \(tally.mismatches) of \(tally.cases) cases (seed \(seed)). \
            First: \(tally.firstMismatch ?? "none")
            """, file: file, line: line)
        // The corpus exists to reach the exact path and the refusals; make sure it still does.
        XCTAssertGreaterThan(tally.rescued, tally.cases / 100,
                             "Too few results that used to trap to exercise the exact path", file: file, line: line)
        XCTAssertGreaterThan(tally.refused, tally.cases / 100,
                             "Too few results that do not fit to exercise refusing them", file: file, line: line)
    }

    func testAdditionMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        let seed: UInt64 = 0x5EED_0000_0000_0010
        let corpus = corpora(seed: seed)
        var tally = Tally()

        tally.check(Operation(name: "add",
                              shipped: Shipped.sum,
                              api: { $0.adding($1, reducing: $2) },
                              core: { Fraction.sum($0.normalized(), $1.normalized(), subtracting: false, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation(name: "add(Int)",
                              shipped: Shipped.sum,
                              api: { $0.adding($1.numerator, reducing: $2) },
                              core: { Fraction.sum($0.normalized(), $1, subtracting: false, reducing: $2) }),
                    on: corpus.integers)
        tally.check(Operation(name: "Int + Fraction",
                              shipped: { Shipped.sum($1, $0) },
                              api: { a, b, _ in a.numerator + b },
                              core: { Fraction.sum($1.normalized(), $0, subtracting: false, reducing: $2) },
                              alwaysReduces: true),
                    on: corpus.integersFirst)

        assertAgrees(tally, seed: seed)
    }

    func testSubtractionMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        let seed: UInt64 = 0x5EED_0000_0000_0011
        let corpus = corpora(seed: seed)
        var tally = Tally()

        tally.check(Operation(name: "subtract",
                              shipped: Shipped.difference,
                              api: { $0.subtracting($1, reducing: $2) },
                              core: { Fraction.sum($0, $1, subtracting: true, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation(name: "subtract(Int)",
                              shipped: Shipped.difference,
                              api: { $0.subtracting($1.numerator, reducing: $2) },
                              core: { Fraction.sum($0, $1, subtracting: true, reducing: $2) }),
                    on: corpus.integers)
        tally.check(Operation(name: "Int - Fraction",
                              shipped: Shipped.difference,
                              api: { a, b, _ in a.numerator - b },
                              core: { Fraction.sum($0, $1, subtracting: true, reducing: $2) },
                              alwaysReduces: true),
                    on: corpus.integersFirst)

        assertAgrees(tally, seed: seed)
    }

    func testMultiplicationMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        let seed: UInt64 = 0x5EED_0000_0000_0012
        let corpus = corpora(seed: seed)
        var tally = Tally()

        tally.check(Operation(name: "multiply",
                              shipped: Shipped.product,
                              api: { $0.multiplying(by: $1, reducing: $2) },
                              core: { Fraction.product($0, $1, reducing: $2) }),
                    on: corpus.fractions)
        tally.check(Operation(name: "multiply(Int)",
                              shipped: Shipped.product,
                              api: { $0.multiplying(by: $1.numerator, reducing: $2) },
                              core: { Fraction.product($0, $1, reducing: $2) }),
                    on: corpus.integers)
        tally.check(Operation(name: "Int * Fraction",
                              shipped: { Shipped.product($1, $0) },
                              api: { a, b, _ in a.numerator * b },
                              core: { Fraction.product($1, $0, reducing: $2) },
                              alwaysReduces: true),
                    on: corpus.integersFirst)

        assertAgrees(tally, seed: seed)
    }

    func testDivisionMatchesTheExactReference() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else {
            throw XCTSkip("The exact reference needs Int128.")
        }
        let seed: UInt64 = 0x5EED_0000_0000_0013
        let corpus = corpora(seed: seed)
        // Dividing by zero throws, or, through nonZeroDivide, is the caller's to avoid.
        let fractions = corpus.fractions.filter { $0.1.numerator != 0 }
        let integers = corpus.integers.filter { $0.1.numerator != 0 }
        let integersFirst = corpus.integersFirst.filter { $0.1.numerator != 0 }
        let reciprocal = { (fraction: Fraction) in unchecked(fraction.denominator, fraction.numerator) }
        var tally = Tally()

        tally.check(Operation(name: "divide",
                              shipped: Shipped.quotient,
                              api: { try! $0.dividing(by: $1, reducing: $2) },
                              core: { Fraction.product($0, reciprocal($1), reducing: $2) }),
                    on: fractions)
        tally.check(Operation(name: "nonZeroDivide",
                              shipped: Shipped.quotient,
                              api: { $0.nonZeroDividing(by: $1, reducing: $2) },
                              core: { Fraction.product($0, reciprocal($1), reducing: $2) }),
                    on: fractions)
        tally.check(Operation(name: "divide(Int)",
                              shipped: Shipped.quotient,
                              api: { try! $0.dividing(by: $1.numerator, reducing: $2) },
                              core: { Fraction.product($0, reciprocal($1), reducing: $2) }),
                    on: integers)
        tally.check(Operation(name: "nonZeroDivide(Int)",
                              shipped: Shipped.quotient,
                              api: { $0.nonZeroDividing(by: $1.numerator, reducing: $2) },
                              core: { Fraction.product($0, reciprocal($1), reducing: $2) }),
                    on: integers)
        tally.check(Operation(name: "Int / Fraction",
                              shipped: Shipped.quotient,
                              api: { a, b, _ in try! a.numerator / b },
                              core: { Fraction.product($0, reciprocal($1), reducing: $2) },
                              alwaysReduces: true),
                    on: integersFirst)

        assertAgrees(tally, seed: seed)
    }
}
