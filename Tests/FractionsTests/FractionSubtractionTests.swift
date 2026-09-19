//
//  FractionSubtractionTests.swift
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

/// Subtraction
class FractionSubtractionTests: XCTestCase {
    func testSubtractionMutating() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        f1_4.subtract(f2_4)
        XCTAssertTrue(f1_4.numerator == -1 && f1_4.denominator == 4, "Incorrect result subtracting \(f2_4.description) from 1/4. Expected -1/4, got \(f1_4.description)")
        
        var fm3_4 = Fraction(numerator: -3, denominator: 4)!
        fm3_4.add(f2_4)
        XCTAssertTrue(fm3_4.numerator == -1 && fm3_4.denominator == 4, "Incorrect result subtracting \(f2_4.description) from \(fm3_4.description). Expected -1/4, got \(fm3_4.description)")
        
        var f1_4bis = Fraction(numerator: 1, denominator: 4)!
        let f3_5 = Fraction(numerator: 3, denominator: 5)!
        f1_4bis.add(f3_5)
        XCTAssertTrue(f1_4bis.numerator == 17 && f1_4bis.denominator == 20, "Incorrect result subtracting \(fm3_4.description) from 1/4. Expected 17/20, got \(f1_4bis.description)")
        
        var f1_4third = Fraction(numerator: 1, denominator: 4)!
        f1_4third.subtract(1)
        XCTAssertTrue(f1_4third.numerator == -3 && f1_4third.denominator == 4, "Incorrect result subtracting 1 from 1/4. Expected -3/4, got \(f1_4third.description)")
        
        var f3_4bis = Fraction(numerator: 3, denominator: 4)!
        f3_4bis.subtract(3)
        XCTAssertTrue(f3_4bis.numerator == -9 && f3_4bis.denominator == 4, "Incorrect result subtracting 3 from 3/4. Expected -9/4, got \(f3_4bis.description)")
    }

    func testSubtractionNonMutating() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f1_4.subtracting(f2_4)
        XCTAssertTrue(result.numerator == -1 && result.denominator == 4, "Incorrect result subtracting \(f2_4.description) from 1/4. Expected -1/4, got \(result.description)")
        
        let f1_4third = Fraction(numerator: 1, denominator: 4)!
        let result2 = f1_4third.subtracting(1)
        XCTAssertTrue(result2.numerator == -3 && result2.denominator == 4, "Incorrect result subtracting 1 from 1/4. Expected -3/4, got \(result2.description)")
        
        let f3_4bis = Fraction(numerator: 3, denominator: 4)!
        let result3 = f3_4bis.subtracting(3)
        XCTAssertTrue(result3.numerator == -9 && result3.denominator == 4, "Incorrect result subtracting 3 from 3/4. Expected -9/4, got \(result3.description)")
    }

    func testSubtractionNonMutatingNonReducing() {
        let f6_8 = Fraction(numerator: 6, denominator: 8)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f6_8.subtracting(f2_4, reducing: false)
        XCTAssertTrue(result.numerator == 8 && result.denominator == 32, "Incorrect result subtracting \(f2_4.description) from 6/8. Expected 8/32, got \(result.description)")
    }

    func testSubtractionOperator() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f1_4 - f2_4
        XCTAssertTrue(result.numerator == -1 && result.denominator == 4, "Incorrect result for 1/4 - 2/4. Expected -1/4, got \(result.description)")
        
        let result2 = 1 - f2_4
        XCTAssertTrue(result2.numerator == 1 && result2.denominator == 2, "Incorrect result for 1 - 2/4. Expected 1/2, got \(result2.description)")
        
        let result3 = f2_4 - 1
        XCTAssertTrue(result3.numerator == -1 && result3.denominator == 2, "Incorrect result for 2/4 - 1. Expected 1/2, got \(result3.description)")
        
        let result3bis = 1 - f2_4
        XCTAssertTrue(result3bis.numerator == 1 && result3bis.denominator == 2, "Incorrect result for 1/4 + 1. Expected 5/4, got \(result3bis.description)")
        
        let result4 = Int(1) - f2_4
        XCTAssertTrue(result4.numerator == 1 && result4.denominator == 2, "Incorrect result for 1 - 2/4. Expected 1/2, got \(result4.description)")
        
        let result5 = f2_4 - Int(1)
        XCTAssertTrue(result5.numerator == -1 && result5.denominator == 2, "Incorrect result for 2/4 - 1. Expected 1/2, got \(result5.description)")
    }

    func testSubtractionCompundAssignmentOperator() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        
        f1_4 -= f3_4
        XCTAssertTrue(f1_4.numerator == -1 && f1_4.denominator == 2, "Incorrect result subtracting \(f3_4.description) from 1/4. Expected -1/2, got \(f1_4.description)")
        
    }
}
