//
//  FractionComparisonDifferentialTests.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Randomised tests pinning down what `==` and `<` mean, so that the implementation behind them
//  can be replaced without changing the answers. See License.md for the license text.

import XCTest
@testable import Fractions

/// The comparison `Fraction` shipped in 1.1.0: reduce and normalize both operands, then compare
/// the stored fields.
///
/// It is reproduced here rather than called, so that the tests keep comparing against the old
/// behaviour after the real implementation changes.
///
/// - Important: This traps on overflow, exactly as the shipped version did. Every test using it
///   must keep both magnitudes at or below `Int(Int32.max)`, which bounds the cross products by
///   `2^62` and so keeps the reference inside its domain.
private func legacyEqual(_ lhs: Fraction, _ rhs: Fraction) -> Bool {
    let left = lhs.reduced().normalized()
    let right = rhs.reduced().normalized()
    return left.numerator == right.numerator && left.denominator == right.denominator
}

private func legacyLess(_ lhs: Fraction, _ rhs: Fraction) -> Bool {
    let left = lhs.reduced().normalized()
    let right = rhs.reduced().normalized()
    return left.numerator * right.denominator < right.numerator * left.denominator
}

/// The largest magnitude for which `legacyLess` is guaranteed not to overflow.
private let legacySafeBound = Int(Int32.max)

/// Comparison, checked by property rather than by example.
class FractionComparisonDifferentialTests: XCTestCase {
    /// `==` and `<` must agree with the 1.1.0 implementation everywhere that implementation
    /// produces an answer at all.
    ///
    /// The corpus mixes three scales: tiny values, where equal-but-differently-spelled fractions
    /// and sign combinations come up densely; the low thousands the benchmark uses; and the
    /// largest magnitudes the reference can handle without trapping.
    func testAgreesWithTheShippedImplementation() {
        let seed: UInt64 = 0x5EED_0000_0000_0001
        var generator = SplitMix64(seed: seed)
        let bounds = [12, 4096, legacySafeBound]
        let iterationsPerBound = 60_000

        for bound in bounds {
            var firstEqualityMismatch: (Fraction, Fraction, Bool, Bool)?
            var firstOrderingMismatch: (Fraction, Fraction, Bool, Bool)?
            var equalityMismatches = 0
            var orderingMismatches = 0

            for _ in 0 ..< iterationsPerBound {
                let lhs = generator.nextFraction(bound: bound)
                let rhs = generator.nextFraction(bound: bound)

                let actualEquality = lhs == rhs
                let expectedEquality = legacyEqual(lhs, rhs)
                if actualEquality != expectedEquality {
                    equalityMismatches += 1
                    if firstEqualityMismatch == nil {
                        firstEqualityMismatch = (lhs, rhs, expectedEquality, actualEquality)
                    }
                }

                let actualOrdering = lhs < rhs
                let expectedOrdering = legacyLess(lhs, rhs)
                if actualOrdering != expectedOrdering {
                    orderingMismatches += 1
                    if firstOrderingMismatch == nil {
                        firstOrderingMismatch = (lhs, rhs, expectedOrdering, actualOrdering)
                    }
                }
            }

            // Asserting once per bound rather than once per iteration keeps the suite fast and
            // reports the offending pair instead of a wall of identical failures.
            XCTAssertEqual(equalityMismatches, 0, """
                == disagrees with the shipped implementation on \(equalityMismatches) of \
                \(iterationsPerBound) pairs at bound \(bound) (seed \(seed)). \
                First: \(firstEqualityMismatch.map { "\($0.0) == \($0.1) should be \($0.2), got \($0.3)" } ?? "none")
                """)
            XCTAssertEqual(orderingMismatches, 0, """
                < disagrees with the shipped implementation on \(orderingMismatches) of \
                \(iterationsPerBound) pairs at bound \(bound) (seed \(seed)). \
                First: \(firstOrderingMismatch.map { "\($0.0) < \($0.1) should be \($0.2), got \($0.3)" } ?? "none")
                """)
        }
    }

    /// Comparison must not care how a fraction is spelled: scaling both fields by the same
    /// non-zero `k` changes the stored form but not the value, so it must change no answer.
    ///
    /// This is the property that makes the reduction in `==` and `<` unnecessary, and unlike the
    /// differential test it needs no reference implementation to be right.
    func testComparisonIsInvariantUnderScaling() {
        let seed: UInt64 = 0x5EED_0000_0000_0002
        var generator = SplitMix64(seed: seed)

        for _ in 0 ..< 50_000 {
            let original = generator.nextFraction(bound: 4096)
            let other = generator.nextFraction(bound: 4096)

            // Keep the scaled fraction inside the range the shipped `<` can handle, so this test
            // is green before the implementation changes as well as after.
            let largestField = Swift.max(original.numerator.magnitude, original.denominator.magnitude)
            let largestScale = Int(UInt(legacySafeBound) / largestField)
            guard largestScale >= 2 else { continue }

            let magnitude = Int.random(in: 2 ... largestScale, using: &generator)
            let scale = Bool.random(using: &generator) ? -magnitude : magnitude
            let scaled = Fraction(verifiedNumerator: original.numerator * scale,
                                  verifiedDenominator: original.denominator * scale)

            XCTAssertEqual(scaled, original, "\(scaled) is \(original) scaled by \(scale) and must equal it (seed \(seed))")
            XCTAssertEqual(scaled < other, original < other, "Scaling \(original) by \(scale) changed its order against \(other) (seed \(seed))")
            XCTAssertEqual(other < scaled, other < original, "Scaling \(original) by \(scale) changed \(other)'s order against it (seed \(seed))")
            XCTAssertEqual(scaled.hashValue, original.hashValue, "\(scaled) and \(original) are equal and must hash equally (seed \(seed))")
        }
    }

    /// The same invariance, driven all the way to the top of `Int`.
    ///
    /// This could not be written against the 1.1.0 implementation: the scaled fractions here have
    /// cross products far beyond `Int.max`, and reducing them first does not help, because the
    /// scale is chosen so that the *other* operand shares no factor with it.
    func testComparisonIsInvariantUnderScalingAtFullRange() {
        let seed: UInt64 = 0x5EED_0000_0000_0006
        var generator = SplitMix64(seed: seed)

        for _ in 0 ..< 50_000 {
            let original = generator.nextFraction(bound: 4096)
            let other = generator.nextFraction(bound: 4096)

            // Scale by as much as `Int` will hold, which is where the old cross products blew up.
            let largestField = Swift.max(original.numerator.magnitude, original.denominator.magnitude)
            let largestScale = Int(UInt(Int.max) / Swift.max(largestField, 1))
            guard largestScale >= 2 else { continue }

            let magnitude = Int.random(in: (largestScale / 2) ... largestScale, using: &generator)
            let scale = Bool.random(using: &generator) ? -magnitude : magnitude

            let scaledNumerator = original.numerator * scale
            let scaledDenominator = original.denominator * scale
            // Int.min is out of the type's range; skip the one scale that could land on it.
            guard scaledNumerator > Int.min, scaledDenominator > Int.min else { continue }

            let scaled = Fraction(verifiedNumerator: scaledNumerator, verifiedDenominator: scaledDenominator)

            XCTAssertEqual(scaled, original, "\(scaled) is \(original) scaled by \(scale) and must equal it (seed \(seed))")
            XCTAssertEqual(scaled < other, original < other, "Scaling \(original) by \(scale) changed its order against \(other) (seed \(seed))")
            XCTAssertEqual(other < scaled, other < original, "Scaling \(original) by \(scale) changed \(other)'s order against it (seed \(seed))")
            XCTAssertEqual(scaled.hashValue, original.hashValue, "\(scaled) and \(original) are equal and must hash equally (seed \(seed))")
        }
    }

    /// `sort()` requires a strict total order. Nothing tested that before.
    func testOrderingIsAStrictTotalOrder() {
        let seed: UInt64 = 0x5EED_0000_0000_0003
        var generator = SplitMix64(seed: seed)

        for _ in 0 ..< 50_000 {
            let a = generator.nextFraction(bound: 12)
            let b = generator.nextFraction(bound: 12)
            let c = generator.nextFraction(bound: 12)

            // Trichotomy: exactly one of <, ==, > holds.
            let relations = [a < b, a == b, b < a].filter { $0 }
            XCTAssertEqual(relations.count, 1, "Exactly one of <, ==, > must hold for \(a) and \(b) (seed \(seed))")

            // Irreflexivity.
            XCTAssertFalse(a < a, "\(a) must not be less than itself (seed \(seed))")

            // Transitivity, which is what a broken comparator usually violates.
            if a < b && b < c {
                XCTAssertTrue(a < c, "\(a) < \(b) < \(c) but not \(a) < \(c) (seed \(seed))")
            }
            if a == b && b == c {
                XCTAssertEqual(a, c, "\(a) == \(b) == \(c) but not \(a) == \(c) (seed \(seed))")
            }
        }
    }

    // MARK: - Magnitudes that used to overflow

    /// In 1.1.0 these trapped: both operands are already in lowest terms, so reducing them saved
    /// nothing and the cross product overflowed `Int`.
    func testLargeCrossProductsCompareWithoutOverflowing() {
        let halfOfMax = Fraction(verifiedNumerator: Int.max, verifiedDenominator: 2)
        let max = Fraction(verifiedNumerator: Int.max, verifiedDenominator: 1)

        XCTAssertTrue(halfOfMax < max, "\(halfOfMax) should be less than \(max)")
        XCTAssertFalse(max < halfOfMax, "\(max) should not be less than \(halfOfMax)")
        XCTAssertNotEqual(halfOfMax, max, "\(halfOfMax) and \(max) are different values")

        let thirdOfMax = Fraction(verifiedNumerator: Int.max, verifiedDenominator: 3)
        let fifth = Fraction(verifiedNumerator: 1, verifiedDenominator: 5)
        XCTAssertTrue(fifth < thirdOfMax, "\(fifth) should be less than \(thirdOfMax)")

        // Equal, but only visible once the products are carried at full width.
        let large = Fraction(verifiedNumerator: Int.max, verifiedDenominator: Int.max - 1)
        let sameLarge = Fraction(verifiedNumerator: Int.max, verifiedDenominator: Int.max - 1)
        XCTAssertEqual(large, sameLarge, "\(large) should equal itself")

        // Extreme operands in both directions: the products here are near ±2^126.
        let mostNegative = Fraction(verifiedNumerator: Int.min + 1, verifiedDenominator: 1)
        let mostPositive = Fraction(verifiedNumerator: Int.max, verifiedDenominator: 1)
        XCTAssertTrue(mostNegative < mostPositive, "\(mostNegative) should be less than \(mostPositive)")
        XCTAssertFalse(mostPositive < mostNegative, "\(mostPositive) should not be less than \(mostNegative)")
    }

    /// Ordering large values must still agree with ordering their reduced forms — the property
    /// that makes dropping the reduction safe, checked where the reduction used to be needed.
    func testLargeValuesOrderAsTheirReducedFormsDo() {
        let big = Int.max / 2
        let half = Fraction(verifiedNumerator: big, verifiedDenominator: 2)
        let quarter = Fraction(verifiedNumerator: big, verifiedDenominator: 4)

        XCTAssertTrue(quarter < half, "\(quarter) should be less than \(half)")
        XCTAssertEqual(Fraction(verifiedNumerator: big, verifiedDenominator: 2),
                       Fraction(verifiedNumerator: big / 3 * 3, verifiedDenominator: 2),
                       "Scaling the numerator by a factor it divides evenly must not change the value")
    }

    // MARK: - Fields outside the type's range

    /// `Int.min` is out of range, but the stored properties are writable, so a fraction can still
    /// be driven there. Comparison must cope; in 1.1.0 it trapped on the negation inside
    /// `reduced()` before it got as far as comparing anything.
    func testIntMinFieldsCompareWithoutTrapping() {
        let intMinNumerator = unchecked(Int.min, 1)

        XCTAssertEqual(intMinNumerator, intMinNumerator, "A fraction must equal itself")
        XCTAssertTrue(intMinNumerator < Fraction.zero, "\(intMinNumerator) should be less than 0/1")
        XCTAssertFalse(Fraction.zero < intMinNumerator, "0/1 should not be less than \(intMinNumerator)")

        // Int.min/1 and Int.min/-1 are negatives of one another, not equal.
        let intMinDenominator = unchecked(Int.min, -1)
        XCTAssertNotEqual(intMinNumerator, intMinDenominator, "\(intMinNumerator) and \(intMinDenominator) differ in sign")
        XCTAssertTrue(intMinNumerator < intMinDenominator, "\(intMinNumerator) should be less than \(intMinDenominator)")

        // Equal values at this magnitude must still compare equal.
        XCTAssertEqual(unchecked(Int.min, 2), unchecked(Int.min / 2, 1),
                       "Int.min/2 should equal \(Int.min / 2)/1")
    }

    /// A zero denominator is documented as unspecified, not as fatal. The requirement is only
    /// that comparing one returns rather than trapping.
    func testZeroDenominatorsDoNotTrap() {
        _ = unchecked(0, 0) == Fraction.one
        _ = unchecked(0, 0) < Fraction.one
        _ = unchecked(5, 0) == unchecked(3, 0)
        _ = unchecked(5, 0) < unchecked(3, 0)
    }
}
