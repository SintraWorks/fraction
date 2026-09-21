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
}
