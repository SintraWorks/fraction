//
//  FractionPowerTests.swift
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

/// Powers
class FractionPowerTests: XCTestCase {
    func testPowerWithPositiveNumerators() throws {
        
        XCTAssertEqual(Fraction.zero.power(of: 0), 1)
        XCTAssertEqual(Fraction.zero.power(of: 1), 0)
        XCTAssertEqual(Fraction.zero.power(of: 2), 0)
        XCTAssertEqual(Fraction.zero.power(of: 3), 0)
        XCTAssertEqual(Fraction.zero.power(of: -1), 0)
        XCTAssertEqual(Fraction.zero.power(of: -2), 0)
        XCTAssertEqual(Fraction.zero.power(of: -3), 0)
        
        XCTAssertEqual(Fraction.one.power(of: 0), 1)
        XCTAssertEqual(Fraction.one.power(of: 1), 1)
        XCTAssertEqual(Fraction.one.power(of: 2), 1)
        XCTAssertEqual(Fraction.one.power(of: 3), 1)
        XCTAssertEqual(Fraction.one.power(of: -1), 1)
        XCTAssertEqual(Fraction.one.power(of: -2), 1)
        XCTAssertEqual(Fraction.one.power(of: -3), 1)
        
        let two = Fraction(verifiedNumerator: 2)
        XCTAssertEqual(two.power(of: 0), 1)
        XCTAssertEqual(two.power(of: 1), 2)
        XCTAssertEqual(two.power(of: 2), 4)
        XCTAssertEqual(two.power(of: 3), 8)
        XCTAssertEqual(two.power(of: 4), 16)
        XCTAssertEqual(two.power(of: 5), 32)
        XCTAssertEqual(two.power(of: -1), 0.5)
        XCTAssertEqual(two.power(of: -2), 0.25)
        XCTAssertEqual(two.power(of: -3), 0.125)
        
        let three = Fraction(verifiedNumerator: 3)
        XCTAssertEqual(three.power(of: 0), 1)
        XCTAssertEqual(three.power(of: 1), 3)
        XCTAssertEqual(three.power(of: 2), 9)
        XCTAssertEqual(three.power(of: 3), 27)
        XCTAssertEqual(three.power(of: -1), Fraction(verifiedNumerator: 1, verifiedDenominator: 3, wholes: 0))
        XCTAssertEqual(three.power(of: -2), Fraction(verifiedNumerator: 1, verifiedDenominator: 9, wholes: 0))
        XCTAssertEqual(three.power(of: -3), Fraction(verifiedNumerator: 1, verifiedDenominator: 27, wholes: 0))
        
        let four = Fraction(verifiedNumerator: 4)
        XCTAssertEqual(four.power(of: 0), 1)
        XCTAssertEqual(four.power(of: 1), 4)
        XCTAssertEqual(four.power(of: 2), 16)
        XCTAssertEqual(four.power(of: 3), 64)
        XCTAssertEqual(four.power(of: -1), Fraction(verifiedNumerator: 1, verifiedDenominator: 4, wholes: 0))
        XCTAssertEqual(four.power(of: -2), Fraction(verifiedNumerator: 1, verifiedDenominator: 16, wholes: 0))
        XCTAssertEqual(four.power(of: -3), Fraction(verifiedNumerator: 1, verifiedDenominator: 64, wholes: 0))
    }

    func testPowerWithNegativeNumerators() throws {
        
        let minusZero = Fraction(verifiedNumerator: -0)
        XCTAssertEqual(minusZero.power(of: 0), 1)
        XCTAssertEqual(minusZero.power(of: 1), 0)
        XCTAssertEqual(minusZero.power(of: 2), 0)
        XCTAssertEqual(minusZero.power(of: 3), 0)
        
        let minusOne = Fraction(verifiedNumerator: -1)
        XCTAssertEqual(minusOne.power(of: 0), 1)
        XCTAssertEqual(minusOne.power(of: 1), -1)
        XCTAssertEqual(minusOne.power(of: 2), 1)
        XCTAssertEqual(minusOne.power(of: 3), -1)
        XCTAssertEqual(minusOne.power(of: -1), -1)
        XCTAssertEqual(minusOne.power(of: -2), 1)
        XCTAssertEqual(minusOne.power(of: -3), -1)
        
        let minusTwo = Fraction(verifiedNumerator: -2)
        XCTAssertEqual(minusTwo.power(of: 0), 1)
        XCTAssertEqual(minusTwo.power(of: 1), -2)
        XCTAssertEqual(minusTwo.power(of: 2), 4)
        XCTAssertEqual(minusTwo.power(of: 3), -8)
        XCTAssertEqual(minusTwo.power(of: -1), -0.5)
        XCTAssertEqual(minusTwo.power(of: -2), 0.25)
        XCTAssertEqual(minusTwo.power(of: -3), -0.125)
        
        let minusThree = Fraction(verifiedNumerator: -3)
        XCTAssertEqual(minusThree.power(of: 0), 1)
        XCTAssertEqual(minusThree.power(of: 1), -3)
        XCTAssertEqual(minusThree.power(of: 2), 9)
        XCTAssertEqual(minusThree.power(of: 3), -27)
        XCTAssertEqual(minusThree.power(of: -1), Fraction(verifiedNumerator: -1, verifiedDenominator: 3, wholes: 0))
        XCTAssertEqual(minusThree.power(of: -2), Fraction(verifiedNumerator: 1, verifiedDenominator: 9, wholes: 0))
        XCTAssertEqual(minusThree.power(of: -3), Fraction(verifiedNumerator: 1, verifiedDenominator: -27, wholes: 0))
    }

    public func dotFactorF(_ dotFactor: Int) -> Fraction {
        if dotFactor == 0 { return .one }
        let dotFactorSquared = 2 << (dotFactor - 1)
        let q = Fraction(numerator: 1, denominator: dotFactorSquared)!
        return 1 + q * (dotFactorSquared - 1)
    }

    public func dotFactor(_ dotFactor: Int) -> Double {
        if dotFactor == 0 { return 1 }
        let dotFactorSquared = pow(2.0, Double(dotFactor))
        return 1 + (1 / dotFactorSquared) * (dotFactorSquared - 1)
    }

    func testDotFactor() {
        for dots in 0 ... 8 {
            XCTAssertEqual(dotFactorF(dots).doubleValue, dotFactor(dots))
        }
    }
}
