//
//  Fraction128Tests.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Fraction128 by example: values and results beyond 64 bits, the exact path at 128, conversions
//  to and from Fraction, and the encoding both types share. See License.md for the license text.

import XCTest
@testable import Fractions

class Fraction128Tests: XCTestCase {
    @available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
    private func assertFields(_ fraction: Fraction128?, _ numerator: Int128, _ denominator: Int128, _ message: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(fraction?.numerator, numerator, message, file: file, line: line)
        XCTAssertEqual(fraction?.denominator, denominator, message, file: file, line: line)
    }

    private static let needsInt128 = "Fraction128 needs Int128, which needs macOS 15, iOS 18, watchOS 11, tvOS 18 or visionOS 2."

    // MARK: Values and results beyond 64 bits

    func testValuesBeyond64Bits() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        let largest: Fraction128 = 170141183460469231731687303715884105727
        XCTAssertEqual(largest.numerator, Int128.max, "An integer literal can reach Int128.max")
        XCTAssertEqual(largest.description, "170141183460469231731687303715884105727/1")

        let third = Fraction128(verifiedNumerator: 1 << 100, verifiedDenominator: 3)
        XCTAssertEqual(third.numerator, 1 << 100, "A numerator of 2^100 fits")
        XCTAssertEqual(Fraction128.maximumSignificantFloatingPointDigits, 38, "10^38 is the largest power of ten Int128 holds")
    }

    /// Results of 77 bits or so, the need `Fraction128` exists for: a `Fraction` refuses them, and
    /// a `Fraction128` computes them exactly.
    func testResultsThatOutgrowFraction() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        // Both operands are in lowest terms, and the numerators share nothing with 15, so the
        // product's numerator, (2^40 + 1)(2^37 - 1), is about 2^77 however it is reduced.
        let a = Fraction(verifiedNumerator: (1 << 40) + 1, verifiedDenominator: 3)
        let b = Fraction(verifiedNumerator: (1 << 37) - 1, verifiedDenominator: 5)
        XCTAssertNil(Fraction.product(a, b, reducing: true), "A 77-bit numerator does not fit in a Fraction")

        let product = Fraction128(a) * Fraction128(b)
        assertFields(product, Int128((1 << 40) + 1) * Int128((1 << 37) - 1), 15, "The product should be exact")
        XCTAssertNil(Fraction(exactly: product), "and should not narrow back into a Fraction")
    }

    // MARK: The exact path at 128 bits

    func testResultsReachedThroughValuesBeyond128Bits() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        // The denominators' product is 2^201.
        let a = Fraction128(verifiedNumerator: 1, verifiedDenominator: 1 << 100)
        let b = Fraction128(verifiedNumerator: 1, verifiedDenominator: 1 << 101)
        assertFields(a + b, 3, 1 << 101, "1/2^100 + 1/2^101 should be 3/2^101")
        assertFields(a - b, 1, 1 << 101, "1/2^100 - 1/2^101 should be 1/2^101")

        // The numerators sum to 2·Int128.max over the shared 2.
        let half = Fraction128(verifiedNumerator: .max, verifiedDenominator: 2)
        assertFields(half + half, .max, 1, "Int128.max/2 + Int128.max/2 should be Int128.max/1")

        let c = Fraction128(verifiedNumerator: 1 << 126, verifiedDenominator: 3)
        let d = Fraction128(verifiedNumerator: 3, verifiedDenominator: 1 << 126)
        assertFields(c * d, 1, 1, "(2^126/3) * (3/2^126) should be 1/1")
        assertFields(try c / c, 1, 1, "(2^126/3) / (2^126/3) should be 1/1")

        // Int128.min is a valid integer operand.
        assertFields(try Fraction128(verifiedNumerator: 2) / Int128.min, 1, -(1 << 126), "2 / Int128.min should be 1/-2^126")
        assertFields(Int128.min - Fraction128(verifiedNumerator: -1), .min + 1, 1, "Int128.min - (-1) should be (Int128.min + 1)/1")
    }

    /// The operations trap exactly where the functions they wrap return nil.
    func testResultsThatDoNotFitAreRefused() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        let largest = Fraction128(verifiedNumerator: .max)
        XCTAssertNil(Fraction128.sum(largest, .one, subtracting: false, reducing: true), "Int128.max + 1 does not fit")
        XCTAssertNil(Fraction128.product(largest, Fraction128(verifiedNumerator: 2), reducing: true), "Int128.max * 2 does not fit")
        XCTAssertNil(Fraction128.sum(Fraction128(verifiedNumerator: -(1 << 126)), Fraction128(verifiedNumerator: 1 << 126),
                                     subtracting: true, reducing: true), "-2^126 - 2^126 lands on Int128.min, which is outside the range")
    }

    // MARK: Everything else, at 128 bits

    func testComparisonAndHashingBeyond64Bits() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        let half = Fraction128(verifiedNumerator: 1, verifiedDenominator: 2)
        let spelledLarge = Fraction128(verifiedNumerator: 1 << 120, verifiedDenominator: 1 << 121)
        XCTAssertEqual(half, spelledLarge, "1/2 and 2^120/2^121 are the same value")
        XCTAssertEqual(half.hashValue, spelledLarge.hashValue, "Equal fractions must hash alike")

        // (M - 1)/M sits just below 1, and above (M - 2)/(M - 1).
        let justBelowOne = Fraction128(verifiedNumerator: .max - 1, verifiedDenominator: .max)
        XCTAssertLessThan(justBelowOne, .one)
        XCTAssertGreaterThan(justBelowOne, Fraction128(verifiedNumerator: .max - 2, verifiedDenominator: .max - 1))
        XCTAssertEqual(Set([half, spelledLarge, justBelowOne]).count, 2, "A Set should hold equal fractions once")
    }

    func testPowerBeyond64Bits() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        var threeToTheEightieth: Int128 = 1
        for _ in 0 ..< 80 { threeToTheEightieth *= 3 }
        let base = Fraction128(verifiedNumerator: 3, verifiedDenominator: 2)
        assertFields(base.power(of: 80), threeToTheEightieth, 1 << 80, "(3/2)^80 should be 3^80/2^80")
        assertFields(base.power(of: -80), 1 << 80, threeToTheEightieth, "(3/2)^-80 should be 2^80/3^80")
    }

    func testFloatConversionBeyond64Bits() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        assertFields(Fraction128(float: 1e30), Int128(exactly: 1e30)!, 1, "1e30 should convert to its exact integer value")
        // Past 22 digits a Double cannot hold the power of ten, so the conversion must not rely on it.
        assertFields(Fraction128(float: 0.5, significantDigits: 38), 1, 2, "0.5 at 38 digits should still be 1/2")
        assertFields(Fraction128(float: -2.25, significantDigits: 30), -9, 4, "-2.25 at 30 digits should still be -9/4")
        XCTAssertNil(Fraction128(approximating: 1e39, significantDigits: 4), "1e39 does not fit in a Fraction128")
    }

    /// Digits past the 22nd used to be zeros whatever the value, so a small value lost its
    /// significant digits there, or vanished altogether.
    func testSmallFloatsKeepTheirDigitsPastTheTwentySecond() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        assertFields(Fraction128(float: 5e-25, significantDigits: 31), 1, 2_000_000_000_000_000_000_000_000,
                     "5e-25 at 31 digits should be 1/(2·10^24), not 0")
        assertFields(Fraction128(float: -1.2345e-20, significantDigits: 30), -2469, 200_000_000_000_000_000_000_000,
                     "-1.2345e-20 at 30 digits should be -12345/10^24, not -123/10^22")
        // A value whose digits end within the first 22 is unaffected.
        assertFields(Fraction128(float: 0.1, significantDigits: 38), 1, 10, "0.1 at 38 digits should still be 1/10")
    }

    /// Every conversion, at every precision, lies within half a unit of its last digit of the
    /// value converted, give or take the precision of the `Double` itself.
    func testFloatConversionIsAccurateAtEveryPrecision() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        let seed: UInt64 = 0x5EED_0000_0000_0040
        var generator = SplitMix64(seed: seed)
        var mismatches = 0
        var firstMismatch: String?

        for _ in 0 ..< 20_000 {
            let magnitude = pow(10.0, Double.random(in: -36 ... 38, using: &generator))
            let value = Double.random(in: -magnitude ... magnitude, using: &generator)
            let digits = Int.random(in: 0 ... Fraction128.maximumSignificantFloatingPointDigits, using: &generator)

            // `init(float:)` would trap on a refusal, and take the test run down with it.
            let converted = Fraction128(approximating: value, significantDigits: digits)
            // Half a unit of the last digit, plus a few units of the Double's last place, for the
            // scaling here and for `doubleValue`.
            let tolerance = 0.5 * pow(10.0, -Double(digits)) + abs(value) * 1e-15
            if converted.map({ abs($0.doubleValue - value) > tolerance }) ?? true {
                mismatches += 1
                if firstMismatch == nil {
                    firstMismatch = "\(value) at \(digits) digits became \(converted.map { "\($0)" } ?? "nil")"
                }
            }
        }

        XCTAssertEqual(mismatches, 0, """
            \(mismatches) of 20000 conversions strayed from their value (seed \(seed)). \
            First: \(firstMismatch ?? "none")
            """)
    }

    // MARK: Conversions

    func testConversionsBetweenWidths() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        // Widening keeps the fields as written.
        let fraction = Fraction(verifiedNumerator: 6, verifiedDenominator: -8)
        let widened = Fraction128(fraction)
        assertFields(widened, 6, -8, "Widening should keep 6/-8 as written")
        XCTAssertTrue(sameFields(Fraction(widened), fraction), "Narrowing it back should give 6/-8")

        // Narrowing keeps the fields when they fit, and falls back to lowest terms when they do not.
        let unreduced = Fraction128(verifiedNumerator: 3 << 100, verifiedDenominator: -(4 << 100))
        let narrowed = Fraction(exactly: unreduced)
        XCTAssertEqual(narrowed?.numerator, 3, "3·2^100/-4·2^100 should narrow to 3/-4")
        XCTAssertEqual(narrowed?.denominator, -4, "3·2^100/-4·2^100 should narrow to 3/-4")

        XCTAssertNil(Fraction(exactly: Fraction128(verifiedNumerator: 1 << 100)), "2^100 does not fit in a Fraction")
        XCTAssertNil(Fraction(exactly: Fraction128(verifiedNumerator: Int128(Int.min))), "Int.min is outside a Fraction's range")
    }

    // MARK: Encoding

    func testEverydayValuesEncodeAsAFractionDoes() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let fraction = Fraction(verifiedNumerator: -3, verifiedDenominator: 4)
        let wide = Fraction128(fraction)
        XCTAssertEqual(try encoder.encode(wide), try encoder.encode(fraction), "A value that fits should encode identically")

        // So each decodes the other's data.
        let fractionFromWide = try JSONDecoder().decode(Fraction.self, from: try encoder.encode(wide))
        XCTAssertTrue(sameFields(fractionFromWide, fraction), "A Fraction should decode a Fraction128's everyday value")
        let wideFromFraction = try JSONDecoder().decode(Fraction128.self, from: try encoder.encode(fraction))
        XCTAssertTrue(sameFields(wideFromFraction, wide), "A Fraction128 should decode a Fraction's value")
    }

    func testValuesBeyond64BitsEncodeAsStrings() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let wide = Fraction128(verifiedNumerator: .max, verifiedDenominator: -(1 << 100))
        let json = String(decoding: try encoder.encode(wide), as: UTF8.self)
        XCTAssertEqual(json, #"{"denominator":"-1267650600228229401496703205376","numerator":"170141183460469231731687303715884105727"}"#)

        let decoded = try JSONDecoder().decode(Fraction128.self, from: Data(json.utf8))
        XCTAssertTrue(sameFields(decoded, wide), "The strings should decode back to the same fields")
        XCTAssertThrowsError(try JSONDecoder().decode(Fraction.self, from: Data(json.utf8)),
                             "A Fraction cannot hold these fields, and should say so rather than trap")
        XCTAssertThrowsError(try JSONDecoder().decode(Fraction128.self, from: Data(#"{"numerator":"one","denominator":"2"}"#.utf8)),
                             "A string that is not an integer should be reported")
    }

    /// `PropertyListEncoder` cannot encode an `Int128` itself, which is what the string form is for.
    func testPropertyListsRoundTrip() throws {
        guard #available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *) else { throw XCTSkip(Self.needsInt128) }

        for value in [Fraction128(verifiedNumerator: 3, verifiedDenominator: -4),
                      Fraction128(verifiedNumerator: .max, verifiedDenominator: 1 << 100)] {
            let data = try PropertyListEncoder().encode([value])
            let decoded = try PropertyListDecoder().decode([Fraction128].self, from: data)
            XCTAssertTrue(sameFields(decoded.first, value), "\(value) should round-trip through a property list")
        }
    }
}
