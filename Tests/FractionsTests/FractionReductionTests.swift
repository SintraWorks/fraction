//
//  FractionReductionTests.swift
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

/// Reduction, normalization and absolute value
class FractionReductionTests: XCTestCase {
    func testReducePositives() {
        var f = Fraction(numerator: 2, denominator: 4)!
        f.reduce()
        XCTAssertTrue(f.numerator == 1 && f.denominator == 2, "Incorrect reduction for 2/4 (got \(f.description), expected 1/2")
        
        let f3_9 = Fraction(numerator: 3, denominator: 9)!
        let f3_9reduced = f3_9.reduced()
        XCTAssertTrue(f3_9reduced.numerator == 1 && f3_9reduced.denominator == 3, "Incorrect reduction for \(f3_9.description) (got \(f3_9reduced.description), expected 1/3")
        
        let f9_3 = Fraction(numerator: 9, denominator: 3)!
        let f9_3reduced = f9_3.reduced()
        XCTAssertTrue(f9_3reduced.numerator == 3 && f9_3reduced.denominator == 1, "Incorrect reduction for \(f9_3.description) (got \(f9_3reduced.description), expected 1/3")
        
        var f2_2 = Fraction(numerator: 2, denominator: 2)!
        f2_2.reduce()
        XCTAssertTrue(f2_2.numerator == 1 && f2_2.denominator == 1, "Incorrect reduction for 2/2 (got \(f2_2.description), expected 1/1")
        
        var f3_3 = Fraction(numerator: 3, denominator: 3)!
        f3_3.reduce()
        XCTAssertTrue(f3_3.numerator == 1 && f3_3.denominator == 1, "Incorrect reduction for 3/3 (got \(f3_3.description), expected 1/1")
        
        var fmax = Fraction(numerator: Int.max, denominator: Int.max)!
        fmax.reduce()
        XCTAssertTrue(fmax.numerator == 1 && fmax.denominator == 1, "Incorrect reduction for Int.max/Int.max (got \(fmax.description), expected 1/1")
        
        var fmax2 = Fraction(numerator: Int.max - 1, denominator: Int.max - 1)!
        fmax2.reduce()
        XCTAssertTrue(fmax2.numerator == 1 && fmax2.denominator == 1, "Incorrect reduction for Int.max-1/Int.max-1 (got \(fmax2.description), expected 1/1")
    }

    func testReduceMixedSigns() {
        var f1 = Fraction(numerator: -3, denominator: 15)!
        f1.reduce()
        XCTAssertTrue(f1.numerator == -1 && f1.denominator == 5, "Incorrect reduction for -3/15 (got \(f1.description), expected -1/5")
        
        var f2 = Fraction(numerator: 3, denominator: -15)!
        f2.reduce()
        XCTAssertTrue(f2.numerator == 1 && f2.denominator == -5, "Incorrect reduction for 3/-15 (got \(f2.description), expected 1/-5")
    }

    func testReduceNegatives() {
        var f = Fraction(numerator: -2, denominator: -4)!
        f.reduce()
        XCTAssertTrue(f.numerator == -1 && f.denominator == -2, "Incorrect reduction for -2/-4 (got \(f.description), expected -1/-2")
        
        let f2 = Fraction(numerator: -3, denominator: -9)!
        let f2Reduced = f2.reduced()
        XCTAssertTrue(f2Reduced.numerator == -1 && f2Reduced.denominator == -3, "Incorrect reduction for -3/-9 (got \(f2Reduced.description), expected -1/-3")
        
        var fmin = Fraction(numerator: Int.min + 1, denominator: Int.min + 1)!
        fmin.reduce()
        XCTAssertTrue(fmin.numerator == -1 && fmin.denominator == -1, "Incorrect reduction for Int.min+1/Int.min+1 (got \(fmin.description), expected -1/-1")
    }

    func testAbs() {
        var f1 = Fraction(numerator: 1, denominator: -1)!
        f1.abs()
        XCTAssertTrue(f1.numerator == 1, "Incorrect abs numerator value for (1, -1) (got \(f1.description)")
        XCTAssertTrue(f1.denominator == 1, "Incorrect abs denominator value for (1, -1) (got \(f1.description)")
        
        var f2 = Fraction(numerator: -1, denominator: 1)!
        f2.abs()
        XCTAssertTrue(f2.numerator == 1, "Incorrect abs numerator value for (-1, 1) (got \(f2.description)")
        XCTAssertTrue(f2.denominator == 1, "Incorrect abs denominator value for (-1, 1) (got \(f2.description)")
        
        var f3 = Fraction(numerator: -1, denominator: -1)!
        f3.abs()
        XCTAssertTrue(f3.numerator == 1, "Incorrect abs numerator value for (-1, -1) (got \(f3.description)")
        XCTAssertTrue(f3.denominator == 1, "Incorrect abs denominator value for (-1, -1) (got \(f3.description)")
        
        var f4 = Fraction(numerator: 1, denominator: 1)!
        f4.abs()
        XCTAssertTrue(f4.numerator == 1, "Incorrect abs numerator value for (1, 1) (got \(f4.description)")
        XCTAssertTrue(f4.denominator == 1, "Incorrect abs denominator value for (1, 1) (got \(f4.description)")
    }

    func testAbsoluted() {
        var absoluted = Fraction(numerator: 1, denominator: -1)!.absoluted()
        XCTAssertTrue(absoluted.numerator == 1, "Incorrect abs numerator value for (1, -1) (got \(absoluted.description)")
        XCTAssertTrue(absoluted.denominator == 1, "Incorrect abs denominator value for (1, -1) (got \(absoluted.description)")

        absoluted = Fraction(numerator: -1, denominator: 1)!.absoluted()
        XCTAssertTrue(absoluted.numerator == 1, "Incorrect abs numerator value for (-1, 1) (got \(absoluted.description)")
        XCTAssertTrue(absoluted.denominator == 1, "Incorrect abs denominator value for (-1, 1) (got \(absoluted.description)")

        absoluted = Fraction(numerator: -1, denominator: -1)!.absoluted()
        XCTAssertTrue(absoluted.numerator == 1, "Incorrect abs numerator value for (-1, -1) (got \(absoluted.description)")
        XCTAssertTrue(absoluted.denominator == 1, "Incorrect abs denominator value for (-1, -1) (got \(absoluted.description)")

        absoluted = Fraction(numerator: 1, denominator: 1)!.absoluted()
        XCTAssertTrue(absoluted.numerator == 1, "Incorrect abs numerator value for (1, 1) (got \(absoluted.description)")
        XCTAssertTrue(absoluted.denominator == 1, "Incorrect abs denominator value for (1, 1) (got \(absoluted.description)")
    }
}
