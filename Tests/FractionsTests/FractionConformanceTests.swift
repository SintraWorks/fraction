//
//  FractionConformanceTests.swift
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

/// Hashable, Sendable and CustomStringConvertible
class FractionConformanceTests: XCTestCase {
    func testDescription() {
        let f = Fraction(numerator: 1, denominator: 4)!
        let description = f.description
        XCTAssertTrue(description == "1/4", "Incorrect description for 1/4 (got \(description.description))")
        
        let f2 = Fraction(numerator: -1, denominator: -4)!
        let description2 = f2.description
        XCTAssertTrue(description2 == "-1/-4", "Incorrect description for -1/-4 (got \(description2.description))")
    }

    func testFractionDescription() {
        let fraction = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)
        XCTAssertEqual("\(fraction)", "1/2", "Interpolation should use description, got \("\(fraction)")")
        XCTAssertEqual(String(describing: fraction), "1/2", "String(describing:) should use description")

        // description reports the stored form, not the canonical one.
        let unreduced = Fraction(verifiedNumerator: 2, verifiedDenominator: 4)
        XCTAssertEqual("\(unreduced)", "2/4", "description should report the stored form")
    }

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

    // A compile-time assertion: this does not build unless Fraction conforms to Sendable.
    func testFractionIsSendable() {
        func requireSendable<T: Sendable>(_ value: T) -> T { value }
        let fraction = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)
        XCTAssertEqual(requireSendable(fraction), fraction, "Fraction should conform to Sendable")
    }

    // Equal values must hash equally. Checked against equality itself over a random corpus,
    // rather than against a list of hand-picked spellings.
    func testEqualValuesHashEqually() {
        let seed: UInt64 = 0x5EED_0000_0000_0004
        var generator = SplitMix64(seed: seed)
        var equalPairsSeen = 0

        for _ in 0 ..< 100_000 {
            let lhs = generator.nextFraction(bound: 12)
            let rhs = generator.nextFraction(bound: 12)
            guard lhs == rhs else { continue }

            equalPairsSeen += 1
            XCTAssertEqual(lhs.hashValue, rhs.hashValue, "\(lhs) == \(rhs) but they hash differently (seed \(seed))")
        }

        // Guard against the test passing silently because nothing compared equal.
        XCTAssertGreaterThan(equalPairsSeen, 1000, "The corpus produced only \(equalPairsSeen) equal pairs, too few to be meaningful")
    }

    // Hashing canonicalizes, so it is the one of the three operations that still reduces — and
    // so the one that could still trap on a field holding Int.min. It must not.
    func testOutOfRangeFieldsHashWithoutTrapping() {
        XCTAssertEqual(unchecked(Int.min, 2).hashValue, unchecked(Int.min / 2, 1).hashValue,
                       "Int.min/2 and \(Int.min / 2)/1 are equal and must hash equally")
        // Int.min/1 and Int.min/-1 are not equal, but they do hash alike: their canonical
        // numerator has magnitude 2^63, which is its own negation, so the sign is lost. Hashable
        // permits unequal values to collide — it only requires that equal ones agree — and a
        // numerator can only reach that magnitude by being written to directly, since no legal
        // numerator exceeds Int.max.
        XCTAssertNotEqual(unchecked(Int.min, 1), unchecked(Int.min, -1),
                          "Int.min/1 and Int.min/-1 differ in sign and are not equal")

        // A zero denominator is documented as unspecified; the requirement is only that it returns.
        _ = unchecked(0, 0).hashValue
        _ = unchecked(5, 0).hashValue
    }
}
