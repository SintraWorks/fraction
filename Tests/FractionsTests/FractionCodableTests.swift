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

    /// The fallback that decodes a plain number used to convert it with trapping arithmetic, so a
    /// number too large for a Fraction, or NaN, crashed the decoding process instead of failing.
    func testDecodingANumberThatDoesNotFitThrows() throws {
        for payload in ["1e30", "-1e19"] {
            XCTAssertThrowsError(try JSONDecoder().decode(Fraction.self, from: Data(payload.utf8)),
                                 "\(payload) does not fit in a Fraction") { error in
                guard case DecodingError.dataCorrupted = error else {
                    return XCTFail("\(payload) should be reported as corrupted data, got \(error)")
                }
            }
        }

        // JSON has no NaN, but a property list can carry one.
        let nan = try PropertyListEncoder().encode([Double.nan])
        XCTAssertThrowsError(try PropertyListDecoder().decode([Fraction].self, from: nan), "NaN does not fit in a Fraction")

        // A large number that does fit decodes; it used to trap as well.
        let large = try JSONDecoder().decode(Fraction.self, from: Data("1e15".utf8))
        XCTAssertEqual(large, Fraction(verifiedNumerator: 1_000_000_000_000_000), "1e15 should decode as 10^15/1")
    }

    /// A bad field used to be retried as a plain number, and reported as that retry's failure,
    /// "expected to decode Double but found a dictionary", whatever the field's fault was.
    func testABadFieldReportsItsOwnError() {
        for (payload, fault) in [(#"{"numerator":"one","denominator":2}"#, "is not an integer"),
                                 (#"{"numerator":"170141183460469231731687303715884105727","denominator":2}"#, "is too wide for a Fraction")] {
            XCTAssertThrowsError(try JSONDecoder().decode(Fraction.self, from: Data(payload.utf8))) { error in
                guard case DecodingError.dataCorrupted(let context) = error else {
                    return XCTFail("A numerator that \(fault) should be reported as corrupted data, got \(error)")
                }
                XCTAssertEqual(context.codingPath.map { $0.stringValue }, ["numerator"], "The error should name the field that \(fault)")
            }
        }

        XCTAssertThrowsError(try JSONDecoder().decode(Fraction.self, from: Data(#"{"numerator":1}"#.utf8))) { error in
            guard case DecodingError.keyNotFound(let key, _) = error else {
                return XCTFail("A missing field should be reported as missing, got \(error)")
            }
            XCTAssertEqual(key.stringValue, "denominator", "The error should name the missing field")
        }

        XCTAssertThrowsError(try JSONDecoder().decode(Fraction.self, from: Data(#"{"numerator":1.5,"denominator":2}"#.utf8))) { error in
            if case DecodingError.typeMismatch(let type, _) = error, type == Double.self {
                XCTFail("A numerator of 1.5 should be reported as the decoder found it, not as a payload that is no Double")
            }
        }
    }
}
