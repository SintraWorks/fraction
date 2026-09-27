//
//  FractionDivisionTests.swift
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

/// Division
class FractionDivisionTests: XCTestCase {
    func testDivisionMutating() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        XCTAssertNoThrow(try f1_4.divide(by: f3_4))
        XCTAssertThrowsError(try f1_4.divide(by: 0))
        XCTAssertTrue(f1_4.numerator == 1 && f1_4.denominator == 3, "Incorrect result dividing 1/4 by \(f3_4.description). Expected 1/3, got \(f1_4.description)")
        
        var f1_4bis = Fraction(numerator: 1, denominator: 4)!
        try! f1_4bis.divide(by: 2)
        XCTAssertTrue(f1_4bis.numerator == 1 && f1_4bis.denominator == 8, "Incorrect result dividing 1/4 by 2. Expected 1/8, got \(f1_4bis.description)")
        
        var f3_4bis = Fraction(numerator: 3, denominator: 4)!
        try! f3_4bis.divide(by: 3)
        XCTAssertTrue(f3_4bis.numerator == 1 && f3_4bis.denominator == 4, "Incorrect result dividing 3 by 3/4. Expected 1/4, got \(f3_4bis.description)")
    }

    func testDivisionNonMutating() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        XCTAssertNoThrow(try f1_4.dividing(by: f3_4))
        let result = try! f1_4.dividing(by: f3_4)
        XCTAssertTrue(result.numerator == 1 && result.denominator == 3, "Incorrect result dividing \(f1_4.description) by \(f3_4.description). Expected 1/3, got \(result.description)")
        
        let f0_4 = Fraction(numerator: 0, denominator: 4)!
        XCTAssertNoThrow(try f0_4.dividing(by: f3_4))
        XCTAssertThrowsError(try f3_4.dividing(by: f0_4))
        XCTAssertThrowsError(try f3_4.dividing(by: 0))
        
        let f1_4bis = Fraction(numerator: 1, denominator: 4)!
        let result2 = try! f1_4bis.dividing(by: 2)
        XCTAssertTrue(result2.numerator == 1 && result2.denominator == 8, "Incorrect result dividing 2 by 1/4. Expected 1/8, got \(result2.description)")
        
        let f3_4bis = Fraction(numerator: 3, denominator: 4)!
        let result3 = try! f3_4bis.dividing(by: 3)
        XCTAssertTrue(result3.numerator == 1 && result3.denominator == 4, "Incorrect result dividing 3 by 3/4. Expected 1/4, got \(result3.description)")
    }

    func testDivisionNonMutatingNonReducing() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        XCTAssertNoThrow(try f1_4.dividing(by: f3_4, reducing: false))
        let result = try! f1_4.dividing(by: f3_4, reducing: false)
        XCTAssertTrue(result.numerator == 4 && result.denominator == 12, "Incorrect result dividing \(f1_4.description) by \(f3_4.description). Expected 4/12, got \(result.description)")
    }

    func testDivisionOperator() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        XCTAssertNoThrow(try f1_4 / f3_4)
        let result = try! f1_4 / f3_4
        XCTAssertTrue(result.numerator == 1 && result.denominator == 3, "Incorrect result dividing \(f1_4.description) by \(f3_4.description). Expected 1/3, got \(result.description)")
        
        let f0_4 = Fraction(numerator: 0, denominator: 4)!
        XCTAssertNoThrow(try f0_4 / f3_4)
        XCTAssertThrowsError(try f3_4 / f0_4)
        
        let result2 = try! 2 / f3_4
        XCTAssertTrue(result2.numerator == 8 && result2.denominator == 3, "Incorrect result dividing 2 by \(f3_4.description). Expected 8/3, got \(result2.description)")
        
        let result3 = try! f3_4 / 2
        XCTAssertTrue(result3.numerator == 3 && result3.denominator == 8, "Incorrect result dividing \(f3_4.description) by 2. Expected 3/8, got \(result3.description)")
        
        let result4 = try! Int(2) / f3_4
        XCTAssertTrue(result4.numerator == 8 && result4.denominator == 3, "Incorrect result dividing 2 by \(f3_4.description). Expected 8/3, got \(result4.description)")
        
        let result5 = try! f3_4 / Int(2)
        XCTAssertTrue(result5.numerator == 3 && result5.denominator == 8, "Incorrect result dividing \(f3_4.description) by 2. Expected 3/8, got \(result5.description)")
        
        XCTAssertNoThrow(try 0 / f3_4)
        XCTAssertThrowsError(try f3_4 / 0)
    }

    func testDivisionCompundAssignmentOperator() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        var f1_4NoThrow = f1_4
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        
        XCTAssertNoThrow(try f1_4NoThrow /= f3_4)
        
        try! f1_4 /= f3_4
        XCTAssertTrue(f1_4.numerator == 1 && f1_4.denominator == 3, "Incorrect result dividing 1/4 by \(f3_4.description). Expected 1/3, got \(f1_4.description)")
        
    }

    func testNonzeroDivideByInteger() {
        var fraction = Fraction(verifiedNumerator: 12, verifiedDenominator: 18)
        fraction.nonZeroDivide(by: 3)
        XCTAssertEqual(fraction.numerator, 2)
        XCTAssertEqual(fraction.denominator, 9)
    }

    func testNonzeroDividingByInteger() {
        let fraction = Fraction(verifiedNumerator: 12, verifiedDenominator: 18)
        let result = fraction.nonZeroDividing(by: 3)
        XCTAssertEqual(result.numerator, 2)
        XCTAssertEqual(result.denominator, 9)
    }

    /// The mutating variant used to drop `reducing` and always reduce.
    func testNonzeroDivideByIntegerWithoutReducing() {
        var fraction = Fraction(verifiedNumerator: 12, verifiedDenominator: 18)
        fraction.nonZeroDivide(by: 3, reducing: false)
        XCTAssertEqual(fraction.numerator, 12, "12/18 divided by 3 without reducing should be 12/54")
        XCTAssertEqual(fraction.denominator, 54, "12/18 divided by 3 without reducing should be 12/54")

        let result = Fraction(verifiedNumerator: 12, verifiedDenominator: 18).nonZeroDividing(by: 3, reducing: false)
        XCTAssertEqual(result.numerator, 12, "12/18 divided by 3 without reducing should be 12/54")
        XCTAssertEqual(result.denominator, 54, "12/18 divided by 3 without reducing should be 12/54")
    }
}
