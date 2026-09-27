//
//  FractionOverflowTests.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Arithmetic traps only when its result does not fit. These pin that down by example: results
//  reached through intermediate values too large for `Int`, and results that are too large
//  themselves. See License.md for the license text.

import XCTest
@testable import Fractions

class FractionOverflowTests: XCTestCase {
    private func assertFields(_ fraction: Fraction?, _ numerator: Int, _ denominator: Int, _ message: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(fraction?.numerator, numerator, message, file: file, line: line)
        XCTAssertEqual(fraction?.denominator, denominator, message, file: file, line: line)
    }

    // MARK: Results that fit, reached through values that do not

    func testSumsWhoseCrossProductsOverflow() {
        let a = Fraction(verifiedNumerator: 1, verifiedDenominator: 1 << 40)
        let b = Fraction(verifiedNumerator: 1, verifiedDenominator: 1 << 41)
        // The denominators' product is 2^81.
        assertFields(a + b, 3, 1 << 41, "1/2^40 + 1/2^41 should be 3/2^41")
        assertFields(a - b, 1, 1 << 41, "1/2^40 - 1/2^41 should be 1/2^41")
    }

    func testSumsWhoseSharedDenominatorNumeratorsOverflow() {
        let half = Fraction(verifiedNumerator: Int.max, verifiedDenominator: 2)
        let negativeHalf = Fraction(verifiedNumerator: -Int.max, verifiedDenominator: 2)
        // The numerators sum to 2·Int.max over the shared 2.
        assertFields(half + half, Int.max, 1, "Int.max/2 + Int.max/2 should be Int.max/1")
        assertFields(half - negativeHalf, Int.max, 1, "Int.max/2 - (-Int.max/2) should be Int.max/1")
    }

    func testIntegerSumsWhoseProductsOverflow() {
        // 2^62 · 2 overflows on the way to (-(2^62 + 1) + 2^63)/2.
        let a = Fraction(verifiedNumerator: -((1 << 62) + 1), verifiedDenominator: 2)
        assertFields(a.adding(1 << 62), (1 << 62) - 1, 2, "-(2^62 + 1)/2 + 2^62 should be (2^62 - 1)/2")

        let b = Fraction(verifiedNumerator: (1 << 62) + 1, verifiedDenominator: 2)
        assertFields(b.subtracting(1 << 62), -((1 << 62) - 1), 2, "(2^62 + 1)/2 - 2^62 should be -(2^62 - 1)/2")
    }

    func testProductsWhoseFieldsOverflow() throws {
        let a = Fraction(verifiedNumerator: 1 << 62, verifiedDenominator: 3)
        let b = Fraction(verifiedNumerator: 3, verifiedDenominator: 1 << 62)
        assertFields(a * b, 1, 1, "(2^62/3) * (3/2^62) should be 1/1")
        assertFields(try a / a, 1, 1, "(2^62/3) / (2^62/3) should be 1/1")

        // Unreduced, 2^62/4 · 4 is 2^64/4.
        assertFields(Fraction(verifiedNumerator: 1 << 62, verifiedDenominator: 4) * 4, 1 << 62, 1,
                     "(2^62/4) * 4 should be 2^62/1")
        // Unreduced, (2^40/2^30) / 2^40 is 2^40/2^70.
        assertFields(try Fraction(verifiedNumerator: 1 << 40, verifiedDenominator: 1 << 30) / (1 << 40), 1, 1 << 30,
                     "(2^40/2^30) / 2^40 should be 1/2^30")
    }

    func testSignsLandWhereTheyAlwaysHave() {
        // subtract and multiply leave a denominator's sign in place, and the exact path has to
        // put it in the same place as the fast path.
        let a = Fraction(verifiedNumerator: 1, verifiedDenominator: -(1 << 40))
        let b = Fraction(verifiedNumerator: 1, verifiedDenominator: 1 << 41)
        assertFields(a - b, 3, -(1 << 41), "1/-2^40 - 1/2^41 should be 3/-2^41")
        // Unreduced, this is 2^41/-2^80: the numerator positive, the denominator negative.
        assertFields(a.subtracting(Fraction(verifiedNumerator: 1, verifiedDenominator: 1 << 40)), 1, -(1 << 39),
                     "1/-2^40 - 1/2^40 should be 1/-2^39")

        let c = Fraction(verifiedNumerator: -(1 << 62), verifiedDenominator: 3)
        let d = Fraction(verifiedNumerator: 3, verifiedDenominator: -(1 << 62))
        assertFields(c * d, -1, -1, "(-2^62/3) * (3/-2^62) should be -1/-1")
    }

    func testUnreducedSumsWhoseProductsOverflow() {
        // 2^62 · 3 overflows, but 2^62 · 3 + (Int.min + 1) · 1 is 2^62 + 1, so the unreduced
        // result fits.
        let a = Fraction(verifiedNumerator: 1 << 62)
        let b = Fraction(verifiedNumerator: Int.min + 1, verifiedDenominator: 3)
        assertFields(a.adding(b, reducing: false), (1 << 62) + 1, 3,
                     "2^62 + (Int.min + 1)/3 without reducing should be (2^62 + 1)/3")
    }

    // MARK: Integer operands of Int.min

    /// `Int.min` is a valid integer operand. The integer overloads used to build a fraction from
    /// it through the failable initializer, which rejects it, and so crashed on a force unwrap.
    func testIntMinIntegerOperands() throws {
        let two = Fraction(verifiedNumerator: 2)
        assertFields(try two / Int.min, 1, -(1 << 62), "2 / Int.min should be 1/-2^62")
        assertFields(Fraction(verifiedNumerator: 4).nonZeroDividing(by: Int.min), 1, -(1 << 61),
                     "4 / Int.min should be 1/-2^61")
        // The denominators' product, -1 · Int.min, overflows on the way.
        assertFields(try Fraction(verifiedNumerator: 2, verifiedDenominator: -1) / Int.min, 1, 1 << 62,
                     "2/-1 / Int.min should be 1/2^62")

        assertFields(Int.min - Fraction(verifiedNumerator: -1), Int.min + 1, 1, "Int.min - (-1) should be (Int.min + 1)/1")
        assertFields(try Int.min / two, Int.min / 2, 1, "Int.min / 2 should be -2^62/1")
        assertFields(Fraction.one + Int.min, Int.min + 1, 1, "1 + Int.min should be (Int.min + 1)/1")
    }

    // MARK: Results that do not fit

    // The public operations trap exactly where the functions they wrap return nil, and a trap
    // cannot be caught in a test, so these check those functions.

    func testSumsThatDoNotFitAreRejected() {
        let max = Fraction(verifiedNumerator: Int.max)
        XCTAssertNil(Fraction.sum(max, .one, subtracting: false, reducing: true), "Int.max + 1 does not fit")
        XCTAssertNil(Fraction.sum(max, Fraction(verifiedNumerator: -1), subtracting: true, reducing: true),
                     "Int.max - (-1) does not fit")

        let half = Fraction(verifiedNumerator: Int.max, verifiedDenominator: 2)
        XCTAssertNotNil(Fraction.sum(half, half, subtracting: false, reducing: true), "Int.max/2 + Int.max/2 fits reduced")
        XCTAssertNil(Fraction.sum(half, half, subtracting: false, reducing: false),
                     "Int.max/2 + Int.max/2 does not fit unreduced: its numerator is 2·Int.max")
    }

    func testProductsThatDoNotFitAreRejected() {
        let max = Fraction(verifiedNumerator: Int.max)
        XCTAssertNil(Fraction.product(max, Fraction(verifiedNumerator: 2), reducing: true), "Int.max * 2 does not fit")
        XCTAssertNil(Fraction.product(Fraction(verifiedNumerator: 1, verifiedDenominator: Int.max),
                                      Fraction(verifiedNumerator: 1, verifiedDenominator: 2), reducing: true),
                     "1/Int.max * 1/2 does not fit")

        let a = Fraction(verifiedNumerator: 1 << 62, verifiedDenominator: 3)
        let b = Fraction(verifiedNumerator: 3, verifiedDenominator: 1 << 62)
        XCTAssertNil(Fraction.product(a, b, reducing: false), "(2^62/3) * (3/2^62) does not fit unreduced")
        // 3 / Int.min is already in lowest terms, and its denominator needs 2^63.
        XCTAssertNil(Fraction.product(Fraction(verifiedNumerator: 3), unchecked(1, Int.min), reducing: true),
                     "3 / Int.min does not fit")
    }

    /// `Int.min` is outside the range, and results that landed on it used to be returned, to trap
    /// later in whatever touched them next.
    func testResultsLandingOnIntMinAreRejected() {
        // -2^62 - 2^62 is exactly Int.min.
        XCTAssertNil(Fraction.sum(Fraction(verifiedNumerator: -(1 << 62)), Fraction(verifiedNumerator: 1 << 62),
                                  subtracting: true, reducing: true), "-2^62 - 2^62 does not fit")
        // 2^62 - (-2^62) is 2^63, which the shared denominator's sign turned into Int.min/-1.
        XCTAssertNil(Fraction.sum(Fraction(verifiedNumerator: -(1 << 62), verifiedDenominator: -1),
                                  Fraction(verifiedNumerator: 1 << 62, verifiedDenominator: -1),
                                  subtracting: true, reducing: true), "2^62 - (-2^62) does not fit")
        // 2^62 · -2 is exactly Int.min.
        XCTAssertNil(Fraction.product(Fraction(verifiedNumerator: 1 << 62), Fraction(verifiedNumerator: -2), reducing: true),
                     "2^62 * -2 does not fit")
    }
}
