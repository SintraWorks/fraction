//
//  Fraction.swift
//  Fractions
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

import math_h

/// A fraction whose numerator and denominator are `Int`s: the type most code uses.
///
/// Everything a fraction can do is documented on ``Rational``, which this is a specialization of.
public typealias Fraction = Rational<Int>

/// The errors a fraction's throwing initializers and operations raise, whatever its integer type.
public enum FractionError: Error {
    case illegalNumerator
    case illegalDenominator
    case illegalDivision
    case decodingError
}

/**
    Rational is a value type that represents the quotient of two integers (like `1/3`), without loss of precision, and with support for basic arithmetic operations.

    The numerator and denominator are of the integer type `Integer`, which decides how large either can grow. ``Fraction`` is `Rational<Int>`.

    The standard initializer is failable. This is because both passing in 0 (for the denominator) and passing in `Integer.min` are illegal. But it can be inconvenient to have to either unwrap or force unwrap all the time when initializing many
    fractions. Therefore the type also provides guaranteed initializers. These will produce non-optional fractions, but if you pass in one of the two illegal values your code will crash.

        // Optional initializer:
        var f1_optional = Fraction(numerator: 1, denominator: 2)
        // Non-Optional initializer:
        var f2_nonOptional = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)

        var f3_nil = Fraction(numerator: 1, denominator: 0)
        var f4_crash = Fraction(verifiedNumerator: 1, verifiedDenominator: 0)

    The type supports addition, subtraction, multiplication and division, both through dedicated functions, and through overloading the corresponding operators.
    E.g. you can add two fractions in any of the following ways:

        var f1 = Fraction(verifiedNumerator: 1, verifiedDenominator: 2)
        let f2 = Fraction(verifiedNumerator: 3, verifiedDenominator: 4, wholes: 2) // 2 + 3/4

        f1.add(f2) // mutating, f1 now holds the result of the addition
        let result1 = f1.adding(f2) // non-mutating
        let result2 = f1 + f2 // non-mutating

    By default arithmetic operations will reduce the result to its **Greatest Common Denominator**. The function based variants allow turning off this behaviour by explicitly forbidding reduction:

        f1.add(f2, reducing: false)

    The type conforms to ExpressibleByIntegerLiteral and to ExpressibleByFloatLiteral. This allows for convenient initalization, and for mixing and matching calculations with literal integers and floats, since
    these will be implicitly converted to fractions. So you can write things like:

        let wholeFraction: Fraction = 3
        let wholeFraction2 = wholeFraction * 2

        let fractionalFraction: Fraction = 3.9
        let fractionalFraction2 = try? fractionalFraction / 3.3

    - Warning: Arithmetic traps when its result does not fit: when the result's numerator or
      denominator falls outside `Integer.min + 1 ... Integer.max`. The result is in lowest terms
      unless you pass `reducing: false`, in which case it is the unreduced result that has to fit.
      An intermediate value too large for `Integer` never causes a trap; it is carried exactly
      instead.
 */
public struct Rational<Integer: FixedWidthInteger & SignedInteger & Sendable>: Sendable {
    /// The number of fraction digits considered when creating a fraction from a floating point
    /// value, unless a call supplies its own.
    ///
    /// Pass `significantDigits` to `init(float:significantDigits:)` to convert at a different
    /// precision. That is a per-call choice rather than a process-wide setting, so it is safe to
    /// use from any concurrency domain and cannot change the meaning of a conversion elsewhere.
    @inlinable
    public static var defaultSignificantFloatingPointDigits: Int { 4 }

    /// The most fraction digits `init(float:significantDigits:)` can preserve: for a `Fraction`,
    /// 18 where `Int` is 64 bits wide, and 9 where it is 32, as on arm64_32 watchOS.
    ///
    /// Preserving `n` digits takes a denominator of 10 to the power `n`, so this is the exponent
    /// of the largest power of ten `Integer` can hold.
    @inlinable
    public static var maximumSignificantFloatingPointDigits: Int {
        var digits = 0
        var power: Integer = 1
        while power <= Integer.max / 10 {
            power *= 10
            digits += 1
        }
        return digits
    }

    /// The errors a fraction raises: the same type whatever `Integer` is.
    public typealias FractionError = Fractions.FractionError

    /// The fraction's numerator (valid range: `Integer.min + 1 ... Integer.max`)
    public var numerator: Integer
    /// The fraction's denominator (valid range: `Integer.min + 1 ... Integer.max`, excluding 0)
    ///
    /// - Warning: This property is writable, so a fraction can be driven outside the type's
    ///   domain after it has been initialized. Assigning 0 is the case that matters: no
    ///   initializer produces a zero denominator, and the results of comparing and hashing a
    ///   fraction that has one are unspecified.
    public var denominator: Integer

    enum CodingKeys: String, CodingKey, CaseIterable {
        case numerator, denominator
    }

    /// Initialize a fraction
    /// - Parameter numerator: The fraction's numerator (valid range: `Integer.min + 1 ... Integer.max`)
    /// - Parameter denominator: The fraction's denominator (valid range: `Integer.min + 1 ... Integer.max`, excluding 0)
    /// - Parameter wholes: The number of wholes, which will be multiplied by the denominator and added to the numerator (valid range: `Integer.min + 1 ... Integer.max`)
    ///
    /// The lower end of the valid range for the parameters is `Integer.min + 1`, because you cannot flip `Integer.min` to to its positive counterpart –it results in an overflow–
    /// which may happen in the `reduce()` function.
    ///
    /// `wholes` is folded into the numerator, so the initializer fails if `denominator * wholes`
    /// overflows, if adding it to `numerator` overflows, or if the result would be `Integer.min` —
    /// all of which are as illegal as passing `Integer.min` for the numerator directly.
    @inlinable
    public init?(numerator: Integer, denominator: Integer, wholes: Integer = 0) {
        guard denominator != 0 else { return nil }
        guard numerator > Integer.min, denominator > Integer.min else { return nil }

        let (offset, offsetOverflowed) = denominator.multipliedReportingOverflow(by: wholes)
        guard !offsetOverflowed else { return nil }
        let (combinedNumerator, sumOverflowed) = numerator.addingReportingOverflow(offset)
        guard !sumOverflowed, combinedNumerator > Integer.min else { return nil }

        self.numerator = combinedNumerator
        self.denominator = denominator
    }

    /// Initialize a fraction from an integer
    /// - Parameter numerator: The fraction's numerator (valid range: `Integer.min + 1 ... Integer.max`)
    ///
    /// The lower end of the valid range for the parameters is `Integer.min + 1`, because you cannot flip `Integer.min` to to its positive counterpart –it results in an overflow–
    /// which may happen in the `reduce()` function. If you pass in `Integer.min` the the initializer will fail.
    @inlinable
    public init?(_ numerator: Integer) {
        guard numerator > Integer.min else { return nil }

        self.numerator = numerator
        self.denominator = 1
    }

    /// Initialize a fraction (guaranteed)
    /// - Parameter verifiedNumerator: The fraction's numerator (valid range: `Integer.min + 1 ... Integer.max`)
    /// - Parameter verifiedDenominator: The fraction's denominator (valid range: `Integer.min + 1 ... Integer.max`, excluding 0)
    /// - Parameter wholes: The number of wholes, which will be multiplied by the denominator and added to the numerator (valid range: `Integer.min + 1 ... Integer.max`)
    ///
    /// It can be very inconvenient to always have to unwrap the initializer. Hence, if you think you know what you are doing, you can use this guaranteed initializer.
    /// Of course, you need to ensure you only pass in valid values. E.g. passing in a 0 for the denominator is a very bad idea. Also, passing `Integer.max` for `wholes`
    /// and a positive fraction with it will result in an arithmetic overflow.
    ///
    /// `wholes` is folded into the numerator, and is checked on the same terms as the numerator
    /// itself: folding it in may neither overflow nor land on `Integer.min`.
    @inlinable
    public init(verifiedNumerator: Integer, verifiedDenominator: Integer = 1, wholes: Integer = 0) {
        precondition(verifiedNumerator > Integer.min, "Illegal numerator value: \(Integer.self).min is not allowed")
        precondition(verifiedDenominator > Integer.min, "Illegal denominator value: \(Integer.self).min is not allowed")
        precondition(verifiedDenominator != 0, "0 is an illegal value for the denominator")

        let (offset, offsetOverflowed) = verifiedDenominator.multipliedReportingOverflow(by: wholes)
        precondition(!offsetOverflowed, "Illegal number of wholes: \(wholes) times a denominator of \(verifiedDenominator) overflows")
        let (combinedNumerator, sumOverflowed) = verifiedNumerator.addingReportingOverflow(offset)
        precondition(!sumOverflowed, "Illegal number of wholes: folding \(wholes) wholes into a numerator of \(verifiedNumerator) overflows")
        precondition(combinedNumerator > Integer.min, "Illegal numerator value: folding \(wholes) wholes into \(verifiedNumerator) yields \(Integer.self).min, which is not allowed")

        self.numerator = combinedNumerator
        self.denominator = verifiedDenominator
    }

    /// Initialize a fraction from a floating point value.
    /// - Parameter float: The value to convert.
    /// - Parameter significantDigits: How many fraction digits of `float` to preserve
    ///   (valid range: 0 ... `maximumSignificantFloatingPointDigits`, which for a `Fraction` is 18
    ///   where `Int` is 64 bits wide). Defaults to `defaultSignificantFloatingPointDigits`.
    ///
    /// The conversion is exact only for values whose fractional part terminates within
    /// `significantDigits` decimal places; anything longer is rounded. `0.5` converts to `1/2`,
    /// while at the default precision `0.123456789` converts to `247/2000`.
    ///
    /// - Note: The upper bound is the exponent of the largest power of ten that fits in `Integer`;
    ///   a higher value would overflow while computing the denominator.
    @inlinable
    public init(float: Double, significantDigits: Int = Rational.defaultSignificantFloatingPointDigits) {
        precondition(significantDigits >= 0, "significantDigits may not be negative, got \(significantDigits)")
        precondition(Rational.powerOfTen(significantDigits) != nil, "significantDigits may not exceed \(Rational.maximumSignificantFloatingPointDigits), as 10 to the power of \(Rational.maximumSignificantFloatingPointDigits + 1) overflows \(Integer.self), got \(significantDigits)")

        guard let fraction = Rational(approximating: float, significantDigits: significantDigits) else {
            preconditionFailure("\(float) does not fit in a fraction of \(Integer.self)")
        }
        self = fraction
    }

    /// `float` rounded to `significantDigits` fraction digits, in lowest terms; `nil` if that does
    /// not fit, which includes NaN and the infinities, or if 10 to the power `significantDigits`
    /// does not.
    ///
    /// The whole part and the fraction digits are added as fractions, so only a result that does
    /// not fit is refused. Folding the whole part into the numerator first, as `wholes · 10^n`,
    /// overflowed for values as small as `1e15`.
    @inlinable
    init?(approximating float: Double, significantDigits: Int) {
        guard let scale = Rational.powerOfTen(significantDigits),
              let wholes = Integer(exactly: float.rounded(.towardZero))
        else { return nil }
        // The fractional part is below 1 in magnitude, so its digits never exceed 10^n.
        let digits = Integer(((float - Double(wholes)) * pow(10.0, Double(significantDigits))).rounded())

        guard let result = Rational.sum(Rational(uncheckedNumerator: digits, denominator: scale),
                                        Rational(uncheckedNumerator: wholes, denominator: 1),
                                        subtracting: false, reducing: true)
        else { return nil }
        self = result
    }

    /// 10 to the power `exponent`, or `nil` if that is negative or overflows `Integer`.
    @inlinable
    static func powerOfTen(_ exponent: Int) -> Integer? {
        guard exponent >= 0 else { return nil }
        var power: Integer = 1
        for _ in 0 ..< exponent {
            let (next, overflow) = power.multipliedReportingOverflow(by: 10)
            guard !overflow else { return nil }
            power = next
        }
        return power
    }

    /// Euclid's algorithm, over magnitudes.
    ///
    /// Working in `Integer.Magnitude` rather than `Integer` is what lets the callers avoid
    /// negating, and so avoid trapping on `Integer.min`. Returns 0 only when both arguments are 0.
    @inlinable
    static func greatestCommonDivisor(_ a: Integer.Magnitude, _ b: Integer.Magnitude) -> Integer.Magnitude {
        var u = a
        var v = b

        while v != 0 {
            (v, u) = (u % v, v)
        }

        return u
    }

    /// Reduce a fraction to its Greatest Common Denominator.
    ///
    /// The sign stays where it was written: `3/-15` reduces to `1/-5`, and `-2/-4` to `-1/-2`.
    /// Use `normalize()` to move a negative sign onto the numerator.
    ///
    /// The reduction is carried out on the magnitudes, so a field holding `Integer.min` reduces
    /// correctly rather than trapping on a negation it cannot represent, and `0/0` — which no
    /// initializer produces — is left alone rather than dividing by zero.
    @inlinable
    public mutating func reduce() {
        let numeratorMagnitude = numerator.magnitude
        let denominatorMagnitude = denominator.magnitude

        let divisor = Rational.greatestCommonDivisor(numeratorMagnitude, denominatorMagnitude)
        guard divisor != 0 else { return }

        let reducedNumerator = numeratorMagnitude / divisor
        let reducedDenominator = denominatorMagnitude / divisor

        // The largest magnitude, one more than `Integer.max`, can only have come from
        // `Integer.min`, which is negative and so takes the negating branch back to `Integer.min`
        // exactly. Every other magnitude is at most `Integer.max`. So neither branch can produce a
        // value `Integer` cannot represent.
        numerator = numerator < 0 ? Integer(truncatingIfNeeded: 0 &- reducedNumerator) : Integer(truncatingIfNeeded: reducedNumerator)
        denominator = denominator < 0 ? Integer(truncatingIfNeeded: 0 &- reducedDenominator) : Integer(truncatingIfNeeded: reducedDenominator)
    }

    /// Returns a new fraction representing the reduction of the receiver to its Greatest Common Denominator
    @inlinable
    public func reduced() -> Rational {
        var copy = self
        copy.reduce()
        return copy
    }

    /// Fractions with two negative signs are normalized to two positive signs.
    /// Fractions with negative denominator are normalized to positive denominator and negative numerator.
    @inlinable
    public mutating func normalize() {
        if numerator >= 0 && denominator >= 0 { return }
        if denominator < 0 {
            numerator *= -1
            denominator *= -1
        }
    }

    /// Returns a normalized copy of `self`.
    /// Fractions with two negative signs are normalized to two positive signs.
    /// Fractions with negative denominator are normalized to positive denominator and negative numerator.
    @inlinable
    public func normalized() -> Rational {
        var copy = self
        copy.normalize()
        return copy
    }

    /// Converts the represented fraction to a Double value.
    /// - Warning: The resulting floating point value may not represent the fraction with absolute accuracy.
    @inlinable
    public var doubleValue: Double {
        Double(numerator) / Double(denominator)
    }

    /// Converts the represented fraction to a Float value.
    /// - Warning: The resulting floating point value may not represent the fraction with absolute accuracy.
    @inlinable
    public var floatValue: Float {
        Float(doubleValue)
    }

    /// Add another fraction to self.
    /// - Parameters:
    ///   - other: The fraction to add.
    ///   - reducing: A flag indicating whether to reduce the result of the addition to its GCD. Defaults to `true`.
    @inlinable
    public mutating func add(_ other: Rational, reducing: Bool = true) {
        guard let sum = Rational.sum(normalized(), other.normalized(), subtracting: false, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) + \(other)", reducing: reducing)
        }
        self = sum
    }

    /// Add an integer to self.
    /// - Parameters:
    ///   - integer: The integer to add.
    ///   - reducing: A flag indicating whether to reduce the result of the addition to its GCD. Defaults to `true`.
    @inlinable
    public mutating func add(_ integer: Integer, reducing: Bool = true) {
        let addend = Rational(uncheckedNumerator: integer, denominator: 1)
        guard let sum = Rational.sum(normalized(), addend, subtracting: false, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) + \(integer)", reducing: reducing)
        }
        self = sum
    }

    /// Add another fraction to a copy of `self` and return the result.
    /// - Parameters:
    ///   - other: The fraction to add.
    ///   - reducing: A flag indicating whether to reduce the result of the addition to its GCD. Defaults to `true`.
    @inlinable
    public func adding(_ other: Rational, reducing: Bool = true) -> Rational {
        var copy = self
        copy.add(other, reducing: reducing)
        return copy
    }

    /// Add an integer to a copy of `self` and return the result.
    /// - Parameters:
    ///   - integer: The integer to add.
    ///   - reducing: A flag indicating whether to reduce the result of the addition to its GCD. Defaults to `true`.
    @inlinable
    public func adding(_ integer: Integer, reducing: Bool = true) -> Rational {
        var copy = self
        copy.add(integer, reducing: reducing)
        return copy
    }

    /// Subtract another fraction from self.
    /// - Parameters:
    ///   - other: The fraction to subtract.
    ///   - reducing: A flag indicating whether to reduce the result of the subtraction to its GCD. Defaults to `true`.
    @inlinable
    public mutating func subtract(_ other: Rational, reducing: Bool = true) {
        guard let difference = Rational.sum(self, other, subtracting: true, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) - \(other)", reducing: reducing)
        }
        self = difference
    }

    /// Subtract an integer from self.
    /// - Parameters:
    ///   - integer: The integer to subtract.
    ///   - reducing: A flag indicating whether to reduce the result of the subtraction to its GCD. Defaults to `true`.
    @inlinable
    public mutating func subtract(_ integer: Integer, reducing: Bool = true) {
        let subtrahend = Rational(uncheckedNumerator: integer, denominator: 1)
        guard let difference = Rational.sum(self, subtrahend, subtracting: true, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) - \(integer)", reducing: reducing)
        }
        self = difference
    }

    /// Subtract another fraction from a copy of `self` and return the result.
    /// - Parameters:
    ///   - other: The fraction to subtract.
    ///   - reducing: A flag indicating whether to reduce the result of the subtraction to its GCD. Defaults to `true`.
    @inlinable
    public func subtracting(_ other: Rational, reducing: Bool = true) -> Rational {
        var copy = self
        copy.subtract(other, reducing: reducing)
        return copy
    }

    /// Subtract an integer from a copy of `self` and return the result.
    /// - Parameters:
    ///   - integer: The integer to subtract.
    ///   - reducing: A flag indicating whether to reduce the result of the subtraction to its GCD. Defaults to `true`.
    @inlinable
    public func subtracting(_ integer: Integer, reducing: Bool = true) -> Rational {
        var copy = self
        copy.subtract(integer, reducing: reducing)
        return copy
    }

    /// Multiply self by another fraction.
    /// - Parameters:
    ///   - other: The fraction to multiply by.
    ///   - reducing: A flag indicating whether to reduce the result of the multiplication to its GCD. Defaults to `true`.
    @inlinable
    public mutating func multiply(by other: Rational, reducing: Bool = true) {
        guard let product = Rational.product(self, other, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) * \(other)", reducing: reducing)
        }
        self = product
    }

    /// Multiply self by an integer.
    /// - Parameters:
    ///   - integer: The integer to multiply by.
    ///   - reducing: A flag indicating whether to reduce the result of the multiplication to its GCD. Defaults to `true`.
    @inlinable
    public mutating func multiply(by integer: Integer, reducing: Bool = true) {
        let multiplier = Rational(uncheckedNumerator: integer, denominator: 1)
        guard let product = Rational.product(self, multiplier, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) * \(integer)", reducing: reducing)
        }
        self = product
    }

    /// Multiply a copy of `self` by another fraction and return the result.
    /// - Parameters:
    ///   - other: The fraction to multiply by.
    ///   - reducing: A flag indicating whether to reduce the result of the multiplication to its GCD. Defaults to `true`.
    @inlinable
    public func multiplying(by other: Rational, reducing: Bool = true) -> Rational {
        var copy = self
        copy.multiply(by: other, reducing:  reducing)
        return copy
    }

    /// Multiply a copy of `self` by an integer and return the result.
    /// - Parameters:
    ///   - integer: The integer to multiply by.
    ///   - reducing: A flag indicating whether to reduce the result of the multiplication to its GCD. Defaults to `true`.
    @inlinable
    public func multiplying(by integer: Integer, reducing: Bool = true) -> Rational {
        var copy = self
        copy.multiply(by: integer, reducing:  reducing)
        return copy
    }

    /// Divide self by another fraction.
    /// - Parameters:
    ///   - other: The fraction to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public mutating func divide(by other: Rational, reducing: Bool = true) throws {
        guard other.numerator != 0 else { throw FractionError.illegalDivision }

        nonZeroDivide(by: other, reducing: reducing)
    }

    /// Divide self by an integer.
    /// - Parameters:
    ///   - integer: The integer to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public mutating func divide(by integer: Integer, reducing: Bool = true) throws {
        guard integer != 0 else { throw FractionError.illegalDivision }

        nonZeroDivide(by: integer, reducing: reducing)
    }

    /// Divide self by another fraction. Caller is taking responsibility to not divide by zero.
    /// - Parameters:
    ///   - other: The fraction to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public mutating func nonZeroDivide(by other: Rational, reducing: Bool = true) {
        // Dividing is multiplying by the divisor with its fields swapped, which spells the result
        // `(a·d)/(b·c)`, as it always has been.
        let reciprocal = Rational(uncheckedNumerator: other.denominator, denominator: other.numerator)
        guard let quotient = Rational.product(self, reciprocal, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) / \(other)", reducing: reducing)
        }
        self = quotient
    }

    /// Divide self by an integer. Caller is taking responsibility to not divide by zero.
    /// - Parameters:
    ///   - integer: The integer to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public mutating func nonZeroDivide(by integer: Integer, reducing: Bool = true) {
        let reciprocal = Rational(uncheckedNumerator: 1, denominator: integer)
        guard let quotient = Rational.product(self, reciprocal, reducing: reducing) else {
            Rational.trapOverflow(of: "\(self) / \(integer)", reducing: reducing)
        }
        self = quotient
    }

    /// Divide a copy of `self` by another fraction and return the result.
    /// - Parameters:
    ///   - other: The fraction to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public func dividing(by other: Rational, reducing: Bool = true) throws -> Rational {
        var copy = self
        try copy.divide(by: other, reducing: reducing)
        return copy
    }

    /// Divide a copy of `self` by an integer and return the result.
    /// - Parameters:
    ///   - integer: The integer to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public func dividing(by integer: Integer, reducing: Bool = true) throws -> Rational {
        guard integer != 0 else { throw FractionError.illegalDivision }

        var copy = self
        try copy.divide(by: integer, reducing: reducing)
        return copy
    }

    /// Divide a copy of `self` by another fraction and return the result. Caller is taking responsibility to not divide by zero.
    /// - Parameters:
    ///   - other: The fraction to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public func nonZeroDividing(by other: Rational, reducing: Bool = true) -> Rational {
        var copy = self
        copy.nonZeroDivide(by: other, reducing: reducing)
        return copy
    }

    /// Divide a copy of `self` by an integer and return the result. Caller is taking responsibility to not divide by zero.
    /// - Parameters:
    ///   - integer: The integer to divide by.
    ///   - reducing: A flag indicating whether to reduce the result of the division to its GCD. Defaults to `true`.
    @inlinable
    public func nonZeroDividing(by integer: Integer, reducing: Bool = true) -> Rational {
        var copy = self
        copy.nonZeroDivide(by: integer, reducing: reducing)
        return copy
    }

    /// Flip `nominator` and `denominator` to their positive counterpart if negative.
    @inlinable
    @discardableResult
    public mutating func abs() -> Self {
        if numerator < 0 {
            numerator *= -1
        }
        if denominator < 0 {
            denominator *= -1
        }

        return self
    }

    @inlinable
    public func absoluted() -> Self {
        var copy = self
        copy.abs()
        return copy
    }
}

extension Rational {
    @inlinable
    public static func + (lhs: Rational, rhs: Rational) -> Rational {
        lhs.adding(rhs)
    }

    @inlinable
    public static func + (lhs: Integer, rhs: Rational) -> Rational {
        rhs.adding(lhs)
    }

    @inlinable
    public static func + (lhs: Rational, rhs: Integer) -> Rational {
        lhs.adding(rhs)
    }

    @inlinable
    public static func += (left: inout Rational, right: Rational) {
        left = left + right
    }

    @inlinable
    public static func - (lhs: Rational, rhs: Rational) -> Rational {
        lhs.subtracting(rhs)
    }

    @inlinable
    public static func - (lhs: Integer, rhs: Rational) -> Rational {
        // Any integer is a valid operand here, `Integer.min` included, which the failable
        // initializer would reject.
        Rational(uncheckedNumerator: lhs, denominator: 1).subtracting(rhs)
    }

    @inlinable
    public static func - (lhs: Rational, rhs: Integer) -> Rational {
        lhs.subtracting(rhs)
    }

    @inlinable
    public static func -= (left: inout Rational, right: Rational) {
        left = left - right
    }

    @inlinable
    public static func * (lhs: Rational, rhs: Rational) -> Rational {
        lhs.multiplying(by: rhs)
    }

    @inlinable
    public static func * (lhs: Integer, rhs: Rational) -> Rational {
        rhs.multiplying(by: lhs)
    }

    @inlinable
    public static func * (lhs: Rational, rhs: Integer) -> Rational {
        lhs.multiplying(by: rhs)
    }

    @inlinable
    public static func *= (left: inout Rational, right: Rational) {
        left = left * right
    }

    @inlinable
    public static func / (lhs: Rational, rhs: Rational) throws -> Rational {
        try lhs.dividing(by: rhs)
    }

    @inlinable
    public static func / (lhs: Integer, rhs: Rational) throws -> Rational {
        // As for `-`: `Integer.min` is a valid operand, which the failable initializer would reject.
        try Rational(uncheckedNumerator: lhs, denominator: 1).dividing(by: rhs)
    }

    @inlinable
    public static func / (lhs: Rational, rhs: Integer) throws -> Rational {
        try lhs.dividing(by: rhs)
    }

    @inlinable
    public static func /= (left: inout Rational, right: Rational) throws {
        left = try left / right
    }
}

extension Rational: Comparable {
    /// Two fractions are equal when they denote the same rational number, however each of them
    /// happens to be written: `1/2`, `2/4`, `50/100` and `-1/-2` are all equal.
    ///
    /// Cross-multiplication is reduction-invariant — `a/b == c/d` exactly when `a·d == c·b`,
    /// whether or not either side is in lowest terms — so no fraction has to be reduced to
    /// compare it, and the sign of `b·d` cancels, so neither has to be normalized. The products
    /// are formed at twice the width of `Integer`, which makes them exact and puts overflow out of
    /// reach.
    ///
    /// - Note: A zero denominator is outside this type's domain; no initializer produces one, and
    ///   the result of comparing such a value is unspecified. See ``denominator``.
    @inlinable
    public static func == (lhs: Rational, rhs: Rational) -> Bool {
        let leftProduct = lhs.numerator.multipliedFullWidth(by: rhs.denominator)
        let rightProduct = rhs.numerator.multipliedFullWidth(by: lhs.denominator)

        return leftProduct.high == rightProduct.high && leftProduct.low == rightProduct.low
    }

    /// Orders two fractions by the rational numbers they denote, regardless of how either is
    /// written.
    ///
    /// `a/b < c/d` holds exactly when `a·d < c·b` for positive `b·d`, and the inequality reverses
    /// when `b·d` is negative. Only the *sign* of `b·d` is needed, and it is read off the two
    /// denominators, so the product itself is never formed and nothing is negated — which is why
    /// this handles values `normalize()` would have trapped on.
    ///
    /// - Note: A zero denominator is outside this type's domain; no initializer produces one, and
    ///   the result of comparing such a value is unspecified. See ``denominator``.
    @inlinable
    public static func < (lhs: Rational, rhs: Rational) -> Bool {
        let leftProduct = lhs.numerator.multipliedFullWidth(by: rhs.denominator)
        let rightProduct = rhs.numerator.multipliedFullWidth(by: lhs.denominator)

        // `multipliedFullWidth(by:)` yields `high · 2^bitWidth + low` with `low` unsigned, which
        // is the two's complement product at twice the width. Such values order lexicographically:
        // signed on the high half, unsigned on the low half.
        if (lhs.denominator < 0) != (rhs.denominator < 0) {
            return rightProduct.high != leftProduct.high
                ? rightProduct.high < leftProduct.high
                : rightProduct.low < leftProduct.low
        } else {
            return leftProduct.high != rightProduct.high
                ? leftProduct.high < rightProduct.high
                : leftProduct.low < rightProduct.low
        }
    }
}

extension Rational: ExpressibleByIntegerLiteral {
    @inlinable
    public init(integerLiteral value: Integer.IntegerLiteralType) {
        self.init(verifiedNumerator: Integer(integerLiteral: value), verifiedDenominator: 1)
    }
}

extension Rational: ExpressibleByFloatLiteral {
    @inlinable
    public init(floatLiteral value: Double) {
        self.init(float: value)
    }
}

extension Rational: Codable where Integer: Codable {
    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            numerator = try container.decode(Integer.self, forKey: .numerator)
            denominator = try container.decode(Integer.self, forKey: .denominator)
            if numerator == Integer.min { throw FractionError.illegalNumerator }
            if denominator == 0 || denominator == Integer.min { throw FractionError.illegalDenominator }
        } catch let error where !(error is FractionError)  {
            let container = try decoder.singleValueContainer()
            let value = try container.decode(Double.self)
            // Decoded data comes from outside, so a value that does not fit is an error to report,
            // not a reason to trap.
            guard let fraction = Rational(approximating: value, significantDigits: Rational.defaultSignificantFloatingPointDigits) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "\(value) does not fit in a fraction of \(Integer.self)")
            }
            numerator = fraction.numerator
            denominator = fraction.denominator
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(numerator, forKey: .numerator)
        try container.encode(denominator, forKey: .denominator)
    }
}

extension Rational {
    public var description: String {
        "\(numerator)/\(denominator)"
    }
}

// MARK: - Helpers -
extension Rational {
    @inlinable
    public static var zero: Rational {
        Rational(verifiedNumerator: 0, verifiedDenominator: 1)
    }

    @inlinable
    public static var one: Rational {
        Rational(verifiedNumerator: 1, verifiedDenominator: 1)
    }
}

public extension Rational {
    /// `self` raised to `exponent`, in lowest terms.
    ///
    /// Any exponent is accepted, `Int.min` included, and as with all arithmetic only a result
    /// that does not fit traps. The work is repeated squaring, so it takes at most two
    /// multiplications per bit of the exponent rather than one per unit of it.
    ///
    /// A negative exponent raises the reciprocal, which is spelled with the fields swapped, as
    /// repeated division has always spelled it. Zero raised to any nonzero exponent, a negative
    /// one included, is zero.
    @inlinable
    func power(of exponent: Int) -> Rational {
        if exponent == 0 { return .one }
        if numerator == 0 { return .zero }
        if exponent == 1 { return self }

        var base = exponent < 0 ? Rational(uncheckedNumerator: denominator, denominator: numerator) : self
        var remaining = exponent.magnitude
        var result = Rational.one
        while true {
            if remaining & 1 == 1 { result *= base }
            remaining >>= 1
            // Squaring only while a higher bit remains keeps every intermediate power below the
            // result, so nothing traps that the result itself would not.
            guard remaining != 0 else { return result }
            base *= base
        }
    }
}
