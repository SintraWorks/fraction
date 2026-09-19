//
//  FractionCodableTests.swift
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

/// Codable
class FractionCodableTests: XCTestCase {
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
