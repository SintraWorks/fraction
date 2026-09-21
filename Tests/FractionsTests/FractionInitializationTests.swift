//
//  FractionInitializationTests.swift
//  FractionsTests
//
//  Created by Antonio Nunes on 16/03/2020.
//  Copyright © 2020 SintraWorks.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this source code and associated documentation files (the "SourceCode"), to deal
//  in the SourceCode without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute copies of the SourceCode, and to
//  sell software using the SourceCode, and permit persons to whom the SourceCode is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the SourceCode.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import XCTest
@testable import Fractions

/// Initialization
class FractionInitializationTests: XCTestCase {
    // Division by 0 is illegal, so the denominator may not be zero.
    // All other values, regardless of sign, should return a Fraction.
    func testFailableInitializer() {
        let illegalFraction = Fraction(numerator: 0, denominator: 0)
        XCTAssertNil(illegalFraction, "denominator 0 is illegal; the initializer should return nil")
        
        let illegalFraction2 = Fraction(numerator: Int.min, denominator: 1)
        XCTAssertNil(illegalFraction2, "numerator Int.min is illegal; the initializer should return nil")
        
        let illegalFraction2bis = Fraction(Int.min)
        XCTAssertNil(illegalFraction2bis, "numerator Int.min is illegal; the initializer should return nil")
        
        let illegalFraction3 = Fraction(numerator: 0, denominator: Int.min)
        XCTAssertNil(illegalFraction3, "denominator Int.min is illegal; the initializer should return nil")
        
        let illegalFraction4 = Fraction(numerator: Int.min, denominator: Int.min)
        XCTAssertNil(illegalFraction4, "numerator Int.min and denominator Int.min are illegal; the initializer should return nil")
        
        let legalFraction1 = Fraction(numerator: 0, denominator: 1)
        XCTAssertNotNil(legalFraction1, "legal parameters (0, 1); the initializer should return a Fraction")
        
        let legalFraction2 = Fraction(numerator: 0, denominator: -1)
        XCTAssertNotNil(legalFraction2, "legal parameters (0, -1); the initializer should return a Fraction")
        
        let legalFraction3 = Fraction(numerator: -1, denominator: -1)
        XCTAssertNotNil(legalFraction3, "legal parameters (-1, -1); the initializer should return a Fraction")
        
        let legalFraction4 = Fraction(numerator: 1, denominator: -1)
        XCTAssertNotNil(legalFraction4, "legal parameters (1, -1); the initializer should return a Fraction")
        
        let legalFraction5 = Fraction(numerator: -1, denominator: 1)
        XCTAssertNotNil(legalFraction5, "legal parameters (-1, 1); the initializer should return a Fraction")
        
        let legalFraction6 = Fraction(numerator: 1, denominator: 1)
        XCTAssertNotNil(legalFraction6, "legal parameters (1, 1); the initializer should return a Fraction")
    }

    func testSucceedingInitializerSanity() {
        let f1 = Fraction(numerator: 1, denominator: -1)!
        XCTAssertTrue(f1.numerator == 1, "Numerator incorrectly assigned (expected 1 got \(f1.numerator)")
        XCTAssertTrue(f1.denominator == -1, "Denominator incorrectly assigned (expected -1 got \(f1.denominator)")
        
        let f2 = Fraction(numerator: -1, denominator: 1)!
        XCTAssertTrue(f2.numerator == -1, "Numerator incorrectly assigned (expected -1 got \(f1.numerator)")
        XCTAssertTrue(f2.denominator == 1, "Denominator incorrectly assigned (expected 1 got \(f1.denominator)")
        
        let almostIntMin = Fraction(numerator: Int.min + 1, denominator: 1)
        XCTAssertNotNil(almostIntMin, "numerator Int.min + 1 is legal; the initializer should succeed")
        
        let intMax = Fraction(numerator: Int.max, denominator: 1)
        XCTAssertNotNil(intMax, "numerator Int.max is legal; the initializer should succeed")
        
        let intMaxBis = Fraction(Int.max)
        XCTAssertNotNil(intMaxBis, "numerator Int.max is legal; the initializer should succeed")
        
        let intMaxVerified = Fraction(verifiedNumerator: Int.max)
        XCTAssertNotNil(intMaxVerified, "numerator Int.max is legal; the initializer should succeed")
    }

    func testVerifiedInitializers() {
        let zero1 = Fraction(verifiedNumerator: 0)
        XCTAssertNotNil(zero1, "Fraction(verifiedNumerator: 0 is legal. Initializer should succeed")
        
        let zero2 = Fraction(verifiedNumerator: 0, verifiedDenominator: 1)
        XCTAssertNotNil(zero2, "Fraction(verifiedNumerator: 0, verifiedDenominator: 1) is legal. Initializer should succeed")
        
        let max = Fraction(verifiedNumerator: 0, verifiedDenominator: 1, wholes: Int.max)
        XCTAssertNotNil(max, "Fraction(verifiedNumerator: 0, verifiedDenominator: 1, wholes: Int.max) is legal. Initializer should succeed")
        XCTAssertEqual(max.numerator, Int.max, "")
        XCTAssertEqual(max.denominator, 1, "")
        
        let maxPlusHalf = Fraction(verifiedNumerator: 1, verifiedDenominator: 2, wholes: 1000)
        XCTAssertNotNil(maxPlusHalf, "Fraction(verifiedNumerator: 0, verifiedDenominator: 1, wholes: 1000) is legal. Initializer should succeed")
        XCTAssertEqual(maxPlusHalf.numerator, 2001, "")
        XCTAssertEqual(maxPlusHalf.denominator, 2, "")
        XCTAssertEqual(maxPlusHalf.floatValue, 1000.5, "")
        
        // Since the initalizers test for valid input through preconditions we can't test for invalid input here.
    }

    func testStaticZero() {
        let zero = Fraction.zero
        XCTAssertTrue(zero.numerator == 0 && zero.denominator == 1)
    }

    func testStaticOne() {
        let one = Fraction.one
        XCTAssertTrue(one.numerator == 1 && one.denominator == 1)
    }

    func testExpressibleByIntegerLiteral() {
        let zero: Fraction = 0
        XCTAssertTrue(zero.numerator == 0, "Literal 0 initialized fraction should have numerator 0, got \(zero.numerator)")
        XCTAssertTrue(zero.denominator == 1, "Literal 0 initialized fraction should have denominator 1, got \(zero.denominator)")
        
        let neg: Fraction = -100000
        XCTAssertTrue(neg.numerator == -100000, "Literal 0 initialized fraction should have numerator -100000, got \(neg.numerator)")
        XCTAssertTrue(neg.denominator == 1, "Literal 0 initialized fraction should have denominator 1, got \(neg.denominator)")
        
        let pos: Fraction = 100000
        XCTAssertTrue(pos.numerator == 100000, "Literal 0 initialized fraction should have numerator 100000, got \(pos.numerator)")
        XCTAssertTrue(pos.denominator == 1, "Literal 0 initialized fraction should have denominator 1, got \(pos.denominator)")
    }

    func testExpressibleByFloatLiteral() {
        let zero: Fraction = 0.0
        XCTAssertTrue(zero.numerator == 0, "Literal 0.0 initialized fraction should have numerator 0, got \(zero.numerator)")
        XCTAssertTrue(zero.denominator == 1, "Literal 0.0 initialized fraction should have denominator 1, got \(zero.denominator)")
        
        let one: Fraction = 1.0
        XCTAssertTrue(one.numerator == 1, "Literal 1.0 initialized fraction should have numerator 1, got \(one.numerator)")
        XCTAssertTrue(one.denominator == 1, "Literal 1.0 initialized fraction should have denominator 1, got \(one.denominator)")
        
        let oneThird: Fraction = 0.333333
        XCTAssertTrue(oneThird.numerator == 3333, "Literal 0.333333 initialized fraction should have numerator 3333, got \(oneThird.numerator)")
        XCTAssertTrue(oneThird.denominator == 10000, "Literal 0.333333 initialized fraction should have denominator 10000, got \(oneThird.denominator)")
        
        let half: Fraction = 0.5
        XCTAssertTrue(half.numerator == 1, "Literal 0.5 initialized fraction should have numerator 1, got \(half.numerator)")
        XCTAssertTrue(half.denominator == 2, "Literal 0.5 initialized fraction should have denominator 2, got \(half.denominator)")
        
        let decimalPlacesRoundingDown: Fraction = 0.1234321
        XCTAssertTrue(decimalPlacesRoundingDown.numerator == 617, "Literal 0.1234321 initialized fraction should have numerator 617, got \(decimalPlacesRoundingDown.numerator)")
        XCTAssertTrue(decimalPlacesRoundingDown.denominator == 5000, "Literal 0.1234321 initialized fraction should have denominator 5000, got \(decimalPlacesRoundingDown.denominator)")
        
        let decimalPlacesRoundingUp: Fraction = 0.123456789
        XCTAssertTrue(decimalPlacesRoundingUp.numerator == 247, "Literal 0.123456789 initialized fraction should have numerator 247, got \(decimalPlacesRoundingUp.numerator)")
        XCTAssertTrue(decimalPlacesRoundingUp.denominator == 2000, "Literal 0.123456789 initialized fraction should have denominator 2000, got \(decimalPlacesRoundingUp.denominator)")
    }

    func testInitFromFloatWithExplicitSignificantDigits() {
        let value = 0.123456789

        let twoDigits = Fraction(float: value, significantDigits: 2)
        XCTAssertEqual(twoDigits, Fraction(verifiedNumerator: 3, verifiedDenominator: 25), "0.123456789 at 2 digits should be 3/25, got \(twoDigits)")

        let fourDigits = Fraction(float: value, significantDigits: 4)
        XCTAssertEqual(fourDigits, Fraction(verifiedNumerator: 247, verifiedDenominator: 2000), "0.123456789 at 4 digits should be 247/2000, got \(fourDigits)")

        let sixDigits = Fraction(float: value, significantDigits: 6)
        XCTAssertEqual(sixDigits, Fraction(verifiedNumerator: 123457, verifiedDenominator: 1000000), "0.123456789 at 6 digits should be 123457/1000000, got \(sixDigits)")

        // 0 digits rounds to the nearest whole number.
        XCTAssertEqual(Fraction(float: value, significantDigits: 0), Fraction.zero, "0.123456789 at 0 digits should be 0/1")
        XCTAssertEqual(Fraction(float: 0.5, significantDigits: 0), Fraction.one, "0.5 at 0 digits should round to 1/1")
    }

    // Omitting significantDigits must behave exactly as passing the default.
    func testInitFromFloatDefaultsToDefaultSignificantDigits() {
        XCTAssertEqual(Fraction.defaultSignificantFloatingPointDigits, 4, "The documented default is 4")

        for value in [0.123456789, 0.5, 3.9, -0.5, -3.9, 0.0] {
            let implicitDigits = Fraction(float: value)
            let explicitDigits = Fraction(float: value, significantDigits: Fraction.defaultSignificantFloatingPointDigits)
            XCTAssertEqual(implicitDigits, explicitDigits, "Converting \(value) with and without an explicit precision should agree, got \(implicitDigits) and \(explicitDigits)")
        }
    }

    // Values with a whole part and a sign go through the same path.
    func testInitFromFloatWithWholePartAndSign() {
        XCTAssertEqual(Fraction(float: 3.9), Fraction(verifiedNumerator: 39, verifiedDenominator: 10), "3.9 should be 39/10, got \(Fraction(float: 3.9))")
        XCTAssertEqual(Fraction(float: -0.5), Fraction(verifiedNumerator: -1, verifiedDenominator: 2), "-0.5 should be -1/2, got \(Fraction(float: -0.5))")
        XCTAssertEqual(Fraction(float: -3.9), Fraction(verifiedNumerator: -39, verifiedDenominator: 10), "-3.9 should be -39/10, got \(Fraction(float: -3.9))")
    }

    // `wholes` is folded into the numerator, and used not to be checked when it was: it could
    // smuggle Int.min past the guards, and overflow past the trap the type promises.
    func testWholesIsRangeChecked() {
        XCTAssertNil(Fraction(numerator: 0, denominator: 1, wholes: Int.min),
                     "Folding Int.min wholes into the numerator yields Int.min, which is illegal")
        XCTAssertNil(Fraction(numerator: -1, denominator: 1, wholes: Int.min + 1),
                     "Folding wholes into the numerator must not overflow")
        XCTAssertNil(Fraction(numerator: 1, denominator: Int.max, wholes: 2),
                     "denominator * wholes must not overflow")
        XCTAssertNil(Fraction(numerator: Int.max, denominator: 1, wholes: 1),
                     "numerator + denominator * wholes must not overflow")

        // Everything legal still works, the existing boundary case included.
        let atMax = Fraction(numerator: 0, denominator: 1, wholes: Int.max)
        XCTAssertEqual(atMax?.numerator, Int.max, "wholes: Int.max with a denominator of 1 is legal")
        XCTAssertEqual(atMax?.denominator, 1, "wholes: Int.max with a denominator of 1 is legal")

        let mixed = Fraction(numerator: 3, denominator: 4, wholes: 2)
        XCTAssertEqual(mixed?.numerator, 11, "2 + 3/4 is 11/4")
        XCTAssertEqual(mixed?.denominator, 4, "2 + 3/4 is 11/4")

        let negativeWholes = Fraction(numerator: 1, denominator: 2, wholes: -3)
        XCTAssertEqual(negativeWholes?.numerator, -5, "-3 + 1/2 is -5/2")
        XCTAssertEqual(negativeWholes?.denominator, 2, "-3 + 1/2 is -5/2")
    }
}
