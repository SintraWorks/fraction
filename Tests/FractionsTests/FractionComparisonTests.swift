//
//  FractionComparisonTests.swift
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

/// Comparable
class FractionComparisonTests: XCTestCase {
    func testComparablePositive() {
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        let f2_8 = Fraction(numerator: 2, denominator: 8)!
        
        let f1_2 = Fraction(numerator: 1, denominator: 2)!
        let f2_4 = Fraction(numerator: 2, denominator: 4)!
        let f3_6 = Fraction(numerator: 3, denominator: 6)!
        let f9_18 = Fraction(numerator: 9, denominator: 18)!
        
        let f1_3 = Fraction(numerator: 1, denominator: 3)!
        let f3_9 = Fraction(numerator: 3, denominator: 9)!
        
        let f6_18 = Fraction(numerator: 6, denominator: 18)!
        
        XCTAssertTrue(f1_4 < f2_4, "Incorrect comparison result for \(f1_4.description) < \(f2_4.description)")
        XCTAssertTrue(f1_4 < f1_2, "Incorrect comparison result for \(f1_4.description) < \(f1_2.description)")
        XCTAssertTrue(f2_8 < f2_4, "Incorrect comparison result for \(f2_8.description) < \(f2_4.description)")
        XCTAssertTrue(f2_8 < f1_2, "Incorrect comparison result for \(f2_8.description) < \(f1_2.description)")
        XCTAssertTrue(f1_4 < f9_18, "Incorrect comparison result for \(f1_4.description) < \(f9_18.description)")
        XCTAssertTrue(f1_3 < f3_6, "Incorrect comparison result for  \(f1_3.description) < \(f3_6.description)")
        XCTAssertTrue(f1_3 < f9_18, "Incorrect comparison result for  \(f1_3.description) < \(f9_18.description)")
        
        XCTAssertTrue(f1_4 == f2_8, "Incorrect comparison result for  \(f1_4.description) < \(f2_8.description)")
        XCTAssertTrue(f2_8 == f1_4, "Incorrect comparison result for  \(f2_8.description) < \(f1_4.description)")
        XCTAssertTrue(f2_8 == f1_4, "Incorrect comparison result for  \(f2_8.description) < \(f1_4.description)")
        XCTAssertTrue(f2_4 == f1_2, "Incorrect comparison result for  \(f2_4.description) < \(f1_2.description)")
        XCTAssertTrue(f1_3 == f3_9, "Incorrect comparison result for  \(f1_3.description) < \(f3_9.description)")
        XCTAssertTrue(f1_3 == f6_18, "Incorrect comparison result for  \(f1_3.description) < \(f6_18.description)")
        XCTAssertTrue(f3_6 == f9_18, "Incorrect comparison result for  \(f3_6.description) < \(f9_18.description)")
        
        XCTAssertFalse(f2_4 == f1_4, "Incorrect comparison result for  \(f2_4.description) != \(f1_4.description)")
    }

    func testComparableNegative() {
        let f1_4 = Fraction(numerator: -1, denominator: -4)!
        let f2_8 = Fraction(numerator: -2, denominator: -8)!
        
        let f1_2 = Fraction(numerator: -1, denominator: -2)!
        let f2_4 = Fraction(numerator: -2, denominator: -4)!
        let f3_6 = Fraction(numerator: -3, denominator: -6)!
        let f9_18 = Fraction(numerator: -9, denominator: -18)!
        
        let f1_3 = Fraction(numerator: -1, denominator: -3)!
        let f3_9 = Fraction(numerator: -3, denominator: -9)!
        
        let f6_18 = Fraction(numerator: -6, denominator: -18)!
        
        XCTAssertTrue(f1_4 < f2_4, "Incorrect comparison result for \(f1_4.description) < \(f2_4.description)")
        XCTAssertTrue(f1_4 < f1_2, "Incorrect comparison result for \(f1_4.description) < \(f1_2.description)")
        XCTAssertTrue(f2_8 < f2_4, "Incorrect comparison result for \(f2_8.description) < \(f2_4.description)")
        XCTAssertTrue(f2_8 < f1_2, "Incorrect comparison result for \(f2_8.description) < \(f1_2.description)")
        XCTAssertTrue(f1_4 < f9_18, "Incorrect comparison result for \(f1_4.description) < \(f9_18.description)")
        XCTAssertTrue(f1_3 < f3_6, "Incorrect comparison result for  \(f1_3.description) < \(f3_6.description)")
        XCTAssertTrue(f1_3 < f9_18, "Incorrect comparison result for  \(f1_3.description) < \(f9_18.description)")
        
        XCTAssertTrue(f1_4 == f2_8, "Incorrect comparison result for  \(f1_4.description) == \(f2_8.description)")
        XCTAssertTrue(f2_8 == f1_4, "Incorrect comparison result for  \(f2_8.description) == \(f1_4.description)")
        XCTAssertTrue(f2_8 == f1_4, "Incorrect comparison result for  \(f2_8.description) == \(f1_4.description)")
        XCTAssertTrue(f2_4 == f1_2, "Incorrect comparison result for  \(f2_4.description) == \(f1_2.description)")
        XCTAssertTrue(f1_3 == f3_9, "Incorrect comparison result for  \(f1_3.description) == \(f3_9.description)")
        XCTAssertTrue(f1_3 == f6_18, "Incorrect comparison result for  \(f1_3.description) == \(f6_18.description)")
        XCTAssertTrue(f3_6 == f9_18, "Incorrect comparison result for  \(f3_6.description) == \(f9_18.description)")
        
        XCTAssertFalse(f2_4 == f1_4, "Incorrect comparison result for  \(f2_4.description) != \(f1_4.description)")
    }

    func testComparableMixedSigns() {
        let fm1_4 = Fraction(numerator: -1, denominator: 4)!
        let f1_m4 = Fraction(numerator: 1, denominator: -4)!
        let fm1_m4 = Fraction(numerator: -1, denominator: -4)!
        let f1_4 = Fraction(numerator: 1, denominator: 4)!
        
        XCTAssertTrue(fm1_4 < f1_4, "Incorrect comparison result for \(fm1_4.description) < \(f1_4.description)")
        XCTAssertTrue(f1_m4 < f1_4, "Incorrect comparison result for \(f1_m4.description) < \(f1_4.description)")
        XCTAssertFalse(fm1_4 > f1_4, "Incorrect comparison result for \(fm1_4.description) < \(f1_4.description)")
        
        XCTAssertTrue(fm1_4 == f1_m4, "Incorrect comparison result for \(fm1_4.description) == \(f1_m4.description)")
        XCTAssertTrue(f1_4 == fm1_m4, "Incorrect comparison result for \(f1_4.description) == \(fm1_m4.description)")
    }
}
