//
//  FractionReductionDifferentialTests.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Pins down `reduce()`'s output — sign placement included — so the algorithm behind it can be
//  replaced without changing what it produces. See License.md for the license text.

import XCTest
@testable import Fractions

/// `reduce()` as it was written in 1.1.0, reproduced so the rewrite can be checked against it.
///
/// - Important: Traps if either field is `Int.min`, and on `0/0`. Callers must stay in range.
private func legacyReduced(_ fraction: Fraction) -> Fraction {
    var copy = fraction
    let (absNumerator, numeratorSign) = copy.numerator < 0 ? (-copy.numerator, -1) : (copy.numerator, 1)
    let (absDenominator, denominatorSign) = copy.denominator < 0 ? (-copy.denominator, -1) : (copy.denominator, 1)

    var u = absNumerator
    var v = absDenominator
    while v != 0 {
        (v, u) = (u % v, v)
    }

    copy.numerator = absNumerator / u * numeratorSign
    copy.denominator = absDenominator / u * denominatorSign
    return copy
}

/// Reduction, checked by property rather than by example.
class FractionReductionDifferentialTests: XCTestCase {
    /// The rewritten `reduce()` must produce byte-identical output to the 1.1.0 version, sign
    /// placement included, everywhere the old one produced output at all.
    func testReduceMatchesTheShippedImplementation() {
        let seed: UInt64 = 0x5EED_0000_0000_0005
        var generator = SplitMix64(seed: seed)
        var mismatches = 0
        var firstMismatch: (Fraction, Fraction, Fraction)?

        for iteration in 0 ..< 100_000 {
            // A mix of small values, where common factors are frequent, and the full legal range.
            let bound = iteration % 2 == 0 ? 64 : Int.max
            let numerator = Int.random(in: (-bound) ... bound, using: &generator)
            var denominator = Int.random(in: (-bound) ... bound, using: &generator)
            if denominator == 0 { denominator = 1 }

            let fraction = Fraction(verifiedNumerator: numerator, verifiedDenominator: denominator)
            let actual = fraction.reduced()
            let expected = legacyReduced(fraction)

            if actual.numerator != expected.numerator || actual.denominator != expected.denominator {
                mismatches += 1
                if firstMismatch == nil { firstMismatch = (fraction, expected, actual) }
            }
        }

        XCTAssertEqual(mismatches, 0, """
            reduce() disagrees with the shipped implementation on \(mismatches) of 100000 values \
            (seed \(seed)). First: \(firstMismatch.map { "\($0.0) should reduce to \($0.1), got \($0.2)" } ?? "none")
            """)
    }

    /// `Int.min` is out of the type's range, but the stored properties are writable, so a fraction
    /// can be driven there. Reducing one must land on the right value rather than trapping on a
    /// negation `Int` cannot represent, which is what 1.1.0 did.
    func testReduceHandlesIntMinFields() {
        // Already in lowest terms.
        var alreadyReduced = unchecked(Int.min, 1)
        alreadyReduced.reduce()
        XCTAssertEqual(alreadyReduced.numerator, Int.min, "Int.min/1 is already in lowest terms")
        XCTAssertEqual(alreadyReduced.denominator, 1, "Int.min/1 is already in lowest terms")

        // Int.min/Int.min reduces to -1/-1, matching how (Int.min + 1)/(Int.min + 1) reduces.
        var both = unchecked(Int.min, Int.min)
        both.reduce()
        XCTAssertEqual(both.numerator, -1, "Int.min/Int.min should reduce to -1/-1")
        XCTAssertEqual(both.denominator, -1, "Int.min/Int.min should reduce to -1/-1")

        // The result leaves the extreme magnitude behind, so it is plainly representable.
        var halvable = unchecked(Int.min, 2)
        halvable.reduce()
        XCTAssertEqual(halvable.numerator, Int.min / 2, "Int.min/2 should reduce to \(Int.min / 2)/1")
        XCTAssertEqual(halvable.denominator, 1, "Int.min/2 should reduce to \(Int.min / 2)/1")

        // The sign still stays where it was written.
        var negativeDenominator = unchecked(Int.min, -2)
        negativeDenominator.reduce()
        XCTAssertEqual(negativeDenominator.numerator, Int.min / 2, "Int.min/-2 should reduce to \(Int.min / 2)/-1")
        XCTAssertEqual(negativeDenominator.denominator, -1, "Int.min/-2 should reduce to \(Int.min / 2)/-1")
    }

    /// 0/0 is unreachable through every initializer, and has no reduced form. Reducing it must be
    /// a no-op rather than a division by the zero greatest common divisor.
    func testReduceLeavesZeroOverZeroAlone() {
        var degenerate = unchecked(0, 0)
        degenerate.reduce()
        XCTAssertEqual(degenerate.numerator, 0, "0/0 has no reduced form and should be left alone")
        XCTAssertEqual(degenerate.denominator, 0, "0/0 has no reduced form and should be left alone")
    }
}
