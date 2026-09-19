//
//  FractionConversionTests.swift
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

/// Conversion to floating point
class FractionConversionTests: XCTestCase {
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
}
