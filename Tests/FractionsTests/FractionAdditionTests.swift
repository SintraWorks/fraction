//
//  FractionAdditionTests.swift
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

/// Addition
class FractionAdditionTests: XCTestCase {
    func testAdditionMutating() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        f1_4.add(f2_4)
        XCTAssertTrue(f1_4.numerator == 3 && f1_4.denominator == 4, "Incorrect result adding \(f2_4.description) to 1/4. Expected 3/4, got \(f1_4.description)")
        
        var fm3_4 = Fraction(numerator: -3, denominator: 4)!
        fm3_4.add(f2_4)
        XCTAssertTrue(fm3_4.numerator == -1 && fm3_4.denominator == 4, "Incorrect result adding \(f2_4) to \(fm3_4.description). Expected -1/4, got \(fm3_4.description)")
        
        var f1_4bis = Fraction(numerator: 1, denominator: 4)!
        let f3_5 = Fraction(numerator: 3, denominator: 5)!
        f1_4bis.add(f3_5)
        XCTAssertTrue(f1_4bis.numerator == 17 && f1_4bis.denominator == 20, "Incorrect result adding \(fm3_4.description) to 1/4. Expected 17/20, got \(f1_4bis.description)")
        
        var f1_4third = Fraction(numerator: 1, denominator: 4)!
        f1_4third.add(1)
        XCTAssertTrue(f1_4third.numerator == 5 && f1_4third.denominator == 4, "Incorrect result adding 1 to 1/4. Expected 5/4, got \(f1_4third.description)")
        
        var f3_4bis = Fraction(numerator: 3, denominator: 4)!
        f3_4bis.add(3)
        XCTAssertTrue(f3_4bis.numerator == 15 && f3_4bis.denominator == 4, "Incorrect result adding 3 to 3/4. Expected 15/4, got \(f3_4bis.description)")
    }

    func testAdditionMutatingWithNegativeSigns() {
        var fm1_4 = Fraction(numerator: -1, denominator: 4)!
        var f1_m4 = Fraction(numerator: 1, denominator: -4)!
        var fm1_m4 = Fraction(numerator: -1, denominator: -4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let f2_m4 = Fraction(numerator: 2, denominator: -4)!
        
        fm1_4.add(f2_4)
        XCTAssertTrue(fm1_4.numerator == 1 && fm1_4.denominator == 4, "Incorrect result adding \(f2_4.description) to -1/4. Expected 1/4, got \(fm1_4.description)")
        
        f1_m4.add(f2_4)
        XCTAssertTrue(f1_m4.numerator == 1 && f1_m4.denominator == 4, "Incorrect result adding \(f2_4.description) to 1/-4. Expected 1/4, got \(f1_m4.description)")
        
        fm1_m4.add(f2_4)
        XCTAssertTrue(fm1_m4.numerator == 3 && fm1_m4.denominator == 4, "Incorrect result adding \(f2_4.description) to -1/-4. Expected 3/4, got \(fm1_m4.description)")
        
        fm1_m4 = Fraction(numerator: -1, denominator: -4)!
        fm1_m4.add(f2_m4)
        XCTAssertTrue(fm1_m4.numerator == -1 && fm1_m4.denominator == 4, "Incorrect result adding \(f2_m4.description) to -1/-4. Expected -1/4, got \(fm1_m4.description)")
        
    }

    func testAdditionNonMutating() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f1_4.adding(f2_4)
        XCTAssertTrue(result.numerator == 3 && result.denominator == 4, "Incorrect result adding \(f2_4.description) to 1/4. Expected 3/4, got \(result.description)")
        
        
        let result1 = f1_4.adding(1)
        XCTAssertTrue(result1.numerator == 5 && result1.denominator == 4, "Incorrect result adding 1 to 1/4. Expected 5/4, got \(result1.description)")
        
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        let result2 = f3_4.adding(3)
        XCTAssertTrue(result2.numerator == 15 && result2.denominator == 4, "Incorrect result adding 3 to 3/4. Expected 15/4, got \(result2.description)")
        
    }

    func testAdditionNonMutatingNonReducing() {
        let f6_8 = Fraction(numerator: 6, denominator: 8)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f6_8.adding(f2_4, reducing: false)
        XCTAssertTrue(result.numerator == 40 && result.denominator == 32, "Incorrect result adding \(f2_4.description) to \(f6_8.description). Expected 40/32, got \(result.description)")
        
        // While we're at it, test some related stuff
        let result2 = f6_8.adding(f2_4, reducing: true)
        XCTAssertTrue(result2.numerator == 5 && result2.denominator == 4, "Incorrect result adding \(f2_4.description) to \(f6_8.description). Expected 5/4, got \(result2.description)")
        
        XCTAssertTrue(result.doubleValue == result2.doubleValue, "Incorrect doubleValue comparison for reducing and non-reducing counterparts")
    }

    func testAdditionNonMutatingExplicitlyReducing() {
        let f6_8 = Fraction(numerator: 6, denominator: 8)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f6_8.adding(f2_4, reducing: true)
        XCTAssertTrue(result.numerator == 5 && result.denominator == 4, "Incorrect result adding \(f2_4.description) to \(f6_8.description). Expected 5/4, got \(result.description)")
        
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        let result2 = f6_8.adding(f3_4, reducing: true)
        XCTAssertTrue(result2.numerator == 3 && result2.denominator == 2, "Incorrect result adding \(f3_4.description) to \(f6_8.description). Expected 3/2, got \(result2.description)")
        
        let result3 = f3_4.adding(f6_8, reducing: true)
        XCTAssertTrue(result3.numerator == 3 && result3.denominator == 2, "Incorrect result adding \(f6_8.description) to \(f3_4.description). Expected 3/2, got \(result3.description)")
    }

    func testAdditionOperator() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let result = f1_4 + f2_4
        XCTAssertTrue(result.numerator == 3 && result.denominator == 4, "Incorrect result for 1/4 + 2/4. Expected 3/4, got \(result.description)")
        
        // Int literals will be automatically converted to a Fraction
        let result2 = 1 + f1_4
        XCTAssertTrue(result2.numerator == 5 && result2.denominator == 4, "Incorrect result for 1 + 1/4. Expected 5/4, got \(result2.description)")
        
        let result3 = f1_4 + 1
        XCTAssertTrue(result3.numerator == 5 && result3.denominator == 4, "Incorrect result for 1/4 + 1. Expected 5/4, got \(result3.description)")
        
        let result3bis = 1 + f1_4
        XCTAssertTrue(result3bis.numerator == 5 && result3bis.denominator == 4, "Incorrect result for 1/4 + 1. Expected 5/4, got \(result3bis.description)")
        
        // By not using a literal, we ensure the mixed Int/Fraction operator is used.
        let result4 = Int(1) + f1_4
        XCTAssertTrue(result4.numerator == 5 && result4.denominator == 4, "Incorrect result for 1 + 1/4. Expected 5/4, got \(result4.description)")
        
        // By not using a literal, we ensure the mixed Fraction/Inr operator is used.
        let result5 = f1_4 + Int(1)
        XCTAssertTrue(result5.numerator == 5 && result5.denominator == 4, "Incorrect result for 1/4 + 1. Expected 5/4, got \(result5.description)")
    }

    func testAdditionCompundAssignmentOperator() {
        var f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f3_4 = Fraction(numerator: 3, denominator: 4)!
        
        f1_4 += f3_4
        XCTAssertTrue(f1_4.numerator == 1 && f1_4.denominator == 1, "Incorrect result adding \(f3_4.description) to 1/4. Expected 1/1, got \(f1_4.description)")
        
    }
}
