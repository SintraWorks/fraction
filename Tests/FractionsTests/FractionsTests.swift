//
//  FractionsTests.swift
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

class FractionsTests: XCTestCase {
    
    // MARK: - Initialization
    
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
    
    // MARK: - Utilities
    
    func testDescription() {
        let f = Fraction(numerator: 1, denominator: 4)!
        let description = f.description
        XCTAssertTrue(description == "1/4", "Incorrect description for 1/4 (got \(description.description))")
        
        let f2 = Fraction(numerator: -1, denominator: -4)!
        let description2 = f2.description
        XCTAssertTrue(description2 == "-1/-4", "Incorrect description for -1/-4 (got \(description2.description))")
    }
    
    func testDoubleValue() {
        let f = Fraction(numerator: 1, denominator: 4)!
        let result = f.doubleValue
        XCTAssertTrue(f.doubleValue == 1.0 / 4.0, "doubleValue of \(f.description) is \(1.0/4.0) (got \(result.description))")
        
        let f2 = Fraction(numerator: 1, denominator: 3)!
        let result2 = f2.doubleValue
        XCTAssertTrue(f2.doubleValue == 1.0 / 3.0, "doubleValue of \(f2.description) is \(1.0/3.0) (got \(result2.description))")
        
        let f3 = Fraction(numerator: 1, denominator: -3)!
        let result3 = f3.doubleValue
        XCTAssertTrue(f3.doubleValue == 1.0 / -3.0, "doubleValue of \(f3.description) is \(1.0 / -3.0) (got \(result3.description))")
        
        let f4 = Fraction(numerator: -1, denominator: -3)!
        let result4 = f4.doubleValue
        XCTAssertTrue(f4.doubleValue == -1.0 / -3.0, "doubleValue of \(f4.description) is \(-1.0 / -3.0) (got \(result4.description))")
        
        let f5 = Fraction(numerator: -1, denominator: 3)!
        let result5 = f5.doubleValue
        XCTAssertTrue(f5.doubleValue == -1.0 / 3.0, "doubleValue of \(f5.description) is \(-1.0 / 3.0) (got \(result5.description))")
    }
    
    func testFloatValue() {
        let f = Fraction(numerator: 1, denominator: 4)!
        let result = f.floatValue
        XCTAssertTrue(f.floatValue == 1.0 / 4.0, "floatValue of \(f.description) is \(1.0/4.0) (got \(result.description))")
        
        let f2 = Fraction(numerator: 1, denominator: 3)!
        let result2 = f2.floatValue
        XCTAssertTrue(f2.floatValue == 1.0 / 3.0, "floatValue of \(f2.description) is \(1.0/3.0) (got \(result2.description))")
        
        let f3 = Fraction(numerator: 1, denominator: -3)!
        let result3 = f3.floatValue
        XCTAssertTrue(f3.floatValue == 1.0 / -3.0, "floatValue of \(f3.description) is \(1.0 / -3.0) (got \(result3.description))")
        
        let f4 = Fraction(numerator: -1, denominator: -3)!
        let result4 = f4.floatValue
        XCTAssertTrue(f4.floatValue == -1.0 / -3.0, "floatValue of \(f4.description) is \(-1.0 / -3.0) (got \(result4.description))")
        
        let f5 = Fraction(numerator: -1, denominator: 3)!
        let result5 = f5.floatValue
        XCTAssertTrue(f5.floatValue == -1.0 / 3.0, "floatValue of \(f5.description) is \(-1.0 / 3.0) (got \(result5.description))")
    }
    
    // MARK: - Reduction
    
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
    
    // MARK: - Absolute
    
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

    // MARK: - Utilities
    
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
    
    // MARK: - Addition
    
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
    
    // MARK: - Subtraction
    
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
    
    // MARK: - Multiplication
    
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
    
    // MARK: - Division
    
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

    // MARK: - Statics and expressible
    
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
        
        Fraction.significantFloatingPointDigits = 2
        let zero2Digits: Fraction = 0.0
        XCTAssertTrue(zero2Digits.numerator == 0, "Literal 0.0 initialized fraction should have numerator 0, got \(zero2Digits.numerator)")
        XCTAssertTrue(zero2Digits.denominator == 1, "Literal 0.0 initialized fraction should have denominator 1, got \(zero2Digits.denominator)")
        Fraction.significantFloatingPointDigits = 4 // Setting back to default, to avoid surprises in ensuing tests.
    }
    
    // MARK: - Verified Initializers

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
    
    // MARK: - Powers
    
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
        
    // MARK: - Decodable
    
    func testDecodableConformanceThrowsOnIllegalInput() throws {
        var payload = #"{ "numerator": 0, "denominator": 0 }"#
        var data = try XCTUnwrap(payload.data(using: .utf8))
        
        do {
            _ = try JSONDecoder().decode(Fraction.self, from: data)
            XCTFail("Decoding this Fraction payload should fail")
        } catch let error as Fraction.FractionError {
            XCTAssertEqual(error, Fraction.FractionError.illegalDenominator)
        }

        payload = #"{ "numerator": \#(Int.min), "denominator": 0 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        
        do {
            _ = try JSONDecoder().decode(Fraction.self, from: data)
            XCTFail("Decoding this Fraction payload should fail")
        } catch let error as Fraction.FractionError {
            XCTAssertEqual(error, Fraction.FractionError.illegalNumerator)
        }

        payload = #"{ "numerator": 0, "denominator": \#(Int.min) }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        
        do {
            _ = try JSONDecoder().decode(Fraction.self, from: data)
            XCTFail("Decoding this Fraction payload should fail")
        } catch let error as Fraction.FractionError {
            XCTAssertEqual(error, Fraction.FractionError.illegalDenominator)
        }
    }
    
    func testDecodableConformanceSucceedsOnLegalInput() throws {
        var payload = #"{ "numerator": 0, "denominator": 1 }"#
        var data = try XCTUnwrap(payload.data(using: .utf8))
        var fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, .zero)

        payload = #"{ "numerator": 1, "denominator": 1 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, .one)

        payload = #"{ "numerator": 3, "denominator": 4 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, 0.75)

        payload = #"{ "numerator": -3, "denominator": 4 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, -0.75)
        
        payload = #"{ "numerator": 3, "denominator": -4 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, -0.75)

        payload = #"{ "numerator": -3, "denominator": -4 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, 0.75)
        
        payload = #"{ "numerator": \#(Int.max), "denominator": 1 }"#
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, Fraction(verifiedNumerator: Int.max))
        
        // We allow decoding from literal numeric values:
        
        payload = "0.75"
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, 0.75)

        payload = "3"
        data = try XCTUnwrap(payload.data(using: .utf8))
        fraction = try JSONDecoder().decode(Fraction.self, from: data)
        XCTAssertEqual(fraction, 3)
    }
}

// MARK: -

// And a bonus practical test:
// In western music notation adding a dot after a note/rest augments it by half its value. Each additional dot adds half again the previously halved value.
extension FractionsTests {
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

// MARK: - Hashable

extension FractionsTests {
    // Equality compares the reduced, normalized form, so fractions that are equal but
    // stored differently must produce the same hash value.
    func testEqualFractionsHashEqually() {
        let half = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)
        let twoQuarters = Fraction(verifiedNumerator: 2, verifiedDenominator: 4)
        let fiftyHundredths = Fraction(verifiedNumerator: 50, verifiedDenominator: 100)

        XCTAssertEqual(half, twoQuarters, "1/2 and 2/4 should be equal")
        XCTAssertEqual(half, fiftyHundredths, "1/2 and 50/100 should be equal")
        XCTAssertEqual(half.hashValue, twoQuarters.hashValue, "Equal fractions must hash equally, got \(half.hashValue) and \(twoQuarters.hashValue)")
        XCTAssertEqual(half.hashValue, fiftyHundredths.hashValue, "Equal fractions must hash equally, got \(half.hashValue) and \(fiftyHundredths.hashValue)")
    }

    // Negative fractions are canonicalized before hashing, so the three spellings of
    // a negative half must all hash alike, and -1/-2 must hash as +1/2.
    func testNegativeFractionsHashEqually() {
        let negativeNumerator = Fraction(verifiedNumerator: -1, verifiedDenominator: 2)
        let negativeDenominator = Fraction(verifiedNumerator: 1, verifiedDenominator: -2)
        let negativeBoth = Fraction(verifiedNumerator: -1, verifiedDenominator: -2)
        let positiveHalf = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)

        XCTAssertEqual(negativeNumerator.hashValue, negativeDenominator.hashValue, "-1/2 and 1/-2 must hash equally")
        XCTAssertEqual(negativeBoth.hashValue, positiveHalf.hashValue, "-1/-2 and 1/2 must hash equally")
        XCTAssertNotEqual(negativeNumerator.hashValue, positiveHalf.hashValue, "-1/2 and 1/2 should not hash equally")
    }

    // Zero has several spellings too, and they must all collapse.
    func testZeroHashesConsistently() {
        let zeroOverOne = Fraction(verifiedNumerator: 0, verifiedDenominator: 1)
        let zeroOverFive = Fraction(verifiedNumerator: 0, verifiedDenominator: 5)
        let zeroOverNegativeFive = Fraction(verifiedNumerator: 0, verifiedDenominator: -5)

        XCTAssertEqual(zeroOverOne.hashValue, zeroOverFive.hashValue, "0/1 and 0/5 must hash equally")
        XCTAssertEqual(zeroOverOne.hashValue, zeroOverNegativeFive.hashValue, "0/1 and 0/-5 must hash equally")
    }

    // The reason the conformance exists: a Fraction has to work as a dictionary key,
    // regardless of the arithmetic path by which it was arrived at.
    func testFractionAsDictionaryKey() {
        let oneTwelfth = Fraction(verifiedNumerator: 1, verifiedDenominator: 12)
        let summed = oneTwelfth + oneTwelfth + oneTwelfth
        let literal = Fraction(verifiedNumerator: 1, verifiedDenominator: 4)
        let unreduced = Fraction(verifiedNumerator: 25, verifiedDenominator: 100)

        var dictionary: [Fraction: String] = [:]
        dictionary[summed] = "summed"
        dictionary[unreduced] = "unreduced"
        dictionary[literal] = "literal"

        XCTAssertEqual(dictionary.count, 1, "All three spellings of 1/4 should be the same key, got \(dictionary.count) entries")
        XCTAssertEqual(dictionary[literal], "literal", "Lookup by an equal fraction should find the stored value")

        let set: Set<Fraction> = [summed, unreduced, literal]
        XCTAssertEqual(set.count, 1, "All three spellings of 1/4 should be one set member, got \(set.count)")
    }
}

// MARK: - Sendable

extension FractionsTests {
    // A compile-time assertion: this does not build unless Fraction conforms to Sendable.
    func testFractionIsSendable() {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let fraction = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)
        XCTAssertEqual(requireSendable(fraction), fraction, "Fraction should conform to Sendable")
    }
}

// MARK: - CustomStringConvertible

extension FractionsTests {
    func testFractionDescription() {
        let fraction = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)
        XCTAssertEqual("\(fraction)", "1/2", "Interpolation should use description, got \("\(fraction)")")
        XCTAssertEqual(String(describing: fraction), "1/2", "String(describing:) should use description")

        // description reports the stored form, not the canonical one.
        let unreduced = Fraction(verifiedNumerator: 2, verifiedDenominator: 4)
        XCTAssertEqual("\(unreduced)", "2/4", "description should report the stored form")
    }
}
