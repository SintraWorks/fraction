//
//  FractionMultiplicationTests.swift
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

/// Multiplication
class FractionMultiplicationTests: XCTestCase {
    func testMultiplicationMutating() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        f1_4.multiply(by: f2_4)
        XCTAssertTrue(f1_4.numerator == 1 && f1_4.denominator == 8, "Incorrect result multiplying 1/4 by \(f2_4.description). Expected 1/8, got \(f1_4.description)")
        
        var fm1_4 = Fraction(numerator: -1, denominator: 4)!
        fm1_4.multiply(by: f2_4)
        XCTAssertTrue(fm1_4.numerator == -1 && fm1_4.denominator == 8, "Incorrect result multiplying -1/4 by \(f2_4.description). Expected -1/8, got \(fm1_4.description)")
        
        var f1_m4 = Fraction(numerator: 1, denominator: -4)!
        f1_m4.multiply(by: f2_4)
        XCTAssertTrue(f1_m4.numerator == 1 && f1_m4.denominator == -8, "Incorrect result multiplying 1/-4 by \(f2_4.description). Expected 1/-8, got \(f1_m4.description)")
        
        
        var f1_4bis = Fraction(numerator: 1, denominator: 4)!
        f1_4bis.multiply(by: 2)
        XCTAssertTrue(f1_4bis.numerator == 1 && f1_4bis.denominator == 2, "Incorrect result multiplying 1/4 by 2. Expected 1/2, got \(f1_4bis.description)")
        
        var f3_4 = Fraction(numerator: 3, denominator: 4)!
        f3_4.multiply(by: 3)
        XCTAssertTrue(f3_4.numerator == 9 && f3_4.denominator == 4, "Incorrect result multiplying 3/4 by 3. Expected 9/4, got \(f3_4.description)")
    }

    func testMultiplicationNonMutating() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f1_4.multiplying(by: f2_4)
        XCTAssertTrue(result.numerator == 1 && result.denominator == 8, "Incorrect result multiplying \(f1_4.description) by \(f2_4.description). Expected 1/8, got \(result.description)")
        
        let f1_4bis = Fraction(numerator: 1, denominator: 4)!
        let result2 = f1_4bis.multiplying(by: 2)
        XCTAssertTrue(result2.numerator == 1 && result2.denominator == 2, "Incorrect result multiplying 2 by 1/4. Expected 1/2, got \(result2.description)")
        
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        let result3 = f3_4.multiplying(by: 3)
        XCTAssertTrue(result3.numerator == 9 && result3.denominator == 4, "Incorrect result multiplying 3 by 3/4. Expected 9/4, got \(result3.description)")
    }

    func testMultiplicationMutatingNonReducing() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        f1_4.multiply(by: f2_4, reducing: false)
        XCTAssertTrue(f1_4.numerator == 2 && f1_4.denominator == 16, "Incorrect result multiplying 1/4 by \(f2_4.description). Expected 2/16, got \(f1_4).description")
    }

    func testMultiplicationOperator() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f1_4 * f2_4
        XCTAssertTrue(result.numerator == 1 && result.denominator == 8, "Incorrect result multiplying \(f1_4.description) by \(f2_4.description). Expected 1/8, got \(result.description)")
        
        let result2 = 2 * f2_4
        XCTAssertTrue(result2.numerator == 1 && result2.denominator == 1, "Incorrect result multiplying 2 by \(f2_4.description). Expected 1/1, got \(result2.description)")
        
        let result3 = f2_4 * 2
        XCTAssertTrue(result3.numerator == 1 && result3.denominator == 1, "Incorrect result multiplying \(result3.description) by 2. Expected 1/1, got \(result3.description)")
        
        let result4 = Int(2) * f2_4
        XCTAssertTrue(result4.numerator == 1 && result4.denominator == 1, "Incorrect result multiplying 2 by \(f2_4.description). Expected 1/1, got \(result4.description)")
        
        let result5 = f2_4 * Int(2)
        XCTAssertTrue(result5.numerator == 1 && result5.denominator == 1, "Incorrect result multiplying \(f2_4.description) by 2. Expected 1/1, got \(result5.description)")
    }

    func testMultiplicationCompundAssignmentOperator() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        
        f1_4 *= f3_4
        XCTAssertTrue(f1_4.numerator == 3 && f1_4.denominator == 16, "Incorrect result multiplying 1/4 by \(f3_4.description). Expected 3/16, got \(f1_4.description)")
        
    }
}
