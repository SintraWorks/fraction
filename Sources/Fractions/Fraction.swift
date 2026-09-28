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

/// A fraction whose numerator and denominator are `Int`s: the type most code uses.
///
/// Everything a fraction can do is documented on ``Rational``, which this is a specialization of.
public typealias Fraction = Rational<Int>

/// A fraction whose numerator and denominator are `Int128`s, for results that outgrow a
/// ``Fraction``.
///
/// Each field holds up to 127 bits, where a `Fraction`'s holds 63. It does everything a `Fraction`
/// does, and converts to and from one with `init(_:)` and `init?(exactly:)`.
///
/// Encoded, each field is a number when it fits in 64 bits, so an everyday value encodes exactly
/// as a `Fraction` does and either type can decode the other's data, and a decimal string when it
/// does not. JSON and property lists can both carry that; `PropertyListEncoder` could not encode
/// an `Int128` itself.
///
/// `Int128` arrived with macOS 15, iOS 18, watchOS 11, tvOS 18 and visionOS 2, hence the
/// availability. A `Fraction` works everywhere it always has.
@available(macOS 15, iOS 18, watchOS 11, tvOS 18, visionOS 2, *)
public typealias Fraction128 = Rational<Int128>

/// The errors a fraction's throwing initializers and operations raise, whatever its integer type.
public enum FractionError: Error {
    case illegalNumerator
    case illegalDenominator
    case illegalDivision
    case decodingError
}

/**
    Rational is a value type that represents the quotient of two integers (like `1/3`), without loss of precision, and with support for basic arithmetic operations.

    The numerator and denominator are of the integer type `Integer`, which decides how large either can grow. ``Fraction`` is `Rational<Int>`, and ``Fraction128``, for results that outgrow it, is `Rational<Int128>`.

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
    /// A `Double` carries only 15 to 17 significant digits, and digits asked for beyond those come
    /// from its binary rounding rather than from the decimal it was written as. So at 38 digits a
    /// ``Fraction128`` converts `0.1` to `1/10`, but `0.123456789` to a fraction a few parts in
    /// 10^17 away from `123456789/10^9`.
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
        let digits = Rational.fractionDigits(of: float - Double(wholes), count: significantDigits)

        guard let result = Rational.sum(Rational(uncheckedNumerator: digits, denominator: scale),
                                        Rational(uncheckedNumerator: wholes, denominator: 1),
                                        subtracting: false, reducing: true)
        else { return nil }
        self = result
    }

    /// The first `count` decimal digits of `fraction`, a value below 1 in magnitude, as an integer
    /// rounded at the last of them: `0.375` to 2 digits is `38`. 10 to the power `count` must fit
    /// in `Integer`, and the result is at most that.
    ///
    /// 10^22 is the largest power of ten a `Double` holds exactly, so the scaling in floating point
    /// stops there: an inexact scale would turn even 0.5 into something not quite 1/2. Any further
    /// digits come from what the scaled value holds below its units. For all but a tiny fraction,
    /// the scaled value is a whole number, and they are zeros: the `Double` has no more to give.
    /// For a tiny one, they are the rest of its significant digits, without which `5e-25` at 31
    /// digits came out as 0. Only an `Integer` wider than 64 bits allows more than 22 digits.
    @inlinable
    static func fractionDigits(of fraction: Double, count: Int) -> Integer {
        let exactCount = Swift.min(count, 22)
        // The power of ten converts from `Integer` exactly, which leaves no need for `pow`, nor
        // for `math_h`, a module Linux does not have.
        let scaled = fraction * Double(powerOfTen(exactCount)!)
        guard count > exactCount else { return Integer(scaled.rounded()) }

        let remainingCount = count - exactCount
        let whole = scaled.rounded(.towardZero)
        let rest = ((scaled - whole) * Double(powerOfTen(remainingCount)!)).rounded()
        // `whole` is below 10^22 and `rest` at most 10^remainingCount, so neither step overflows.
        return Integer(whole) * powerOfTen(remainingCount)! + Integer(rest)
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
        if Integer.Magnitude.bitWidth > UInt64.bitWidth {
            return wideGreatestCommonDivisor(a, b)
        }

        var u = a
        var v = b

        while v != 0 {
            (v, u) = (u % v, v)
        }

        return u
    }

    /// The greatest common divisor where `Integer` is wider than 64 bits, and so its division runs
    /// in software, several times slower than the hardware's.
    ///
    /// Stein's binary algorithm, which needs only shifts and subtractions, works the values down
    /// until the smaller fits in 64 bits. Then one division brings the larger below it too, and
    /// Euclid finishes in hardware.
    @inlinable
    static func wideGreatestCommonDivisor(_ a: Integer.Magnitude, _ b: Integer.Magnitude) -> Integer.Magnitude {
        if a == 0 { return b }
        if b == 0 { return a }

        // gcd(2^i·u, 2^j·v) = 2^min(i, j) · gcd(u, v), and from here on u and v are odd.
        let shift = (a | b).trailingZeroBitCount
        var u = a >> a.trailingZeroBitCount
        var v = b >> b.trailingZeroBitCount

        while true {
            if u > v { swap(&u, &v) }
            if let narrowU = UInt64(exactly: u) {
                // gcd(u, v) = gcd(u, v mod u), and v mod u is below u, so both now fit.
                let remainder = UInt64(truncatingIfNeeded: v % u)
                return Integer.Magnitude(Rational<Int64>.greatestCommonDivisor(narrowU, remainder)) << shift
            }
            // gcd(u, v) = gcd(u, v - u), and v - u of two odd values is even: shift it odd again.
            v -= u
            if v == 0 { return u << shift }
            v >>= v.trailingZeroBitCount
        }
    }

    /// Both magnitudes divided by their greatest common divisor; `nil` for 0 and 0, which have
    /// none.
    ///
    /// Division wider than a machine word runs in software, several times slower than the
    /// hardware's. So where `Integer` is wider than 64 bits, a pair that fits in 64 bits is reduced
    /// in 64 bits, which is what keeps a `Fraction128` holding everyday values nearly as fast as a
    /// `Fraction`. The test is on a constant, so narrower types do not pay for it.
    @inlinable
    static func lowestTerms(_ numerator: Integer.Magnitude, _ denominator: Integer.Magnitude)
        -> (numerator: Integer.Magnitude, denominator: Integer.Magnitude)? {
        if Integer.Magnitude.bitWidth > UInt64.bitWidth,
           let narrowNumerator = UInt64(exactly: numerator),
           let narrowDenominator = UInt64(exactly: denominator) {
            guard let narrow = Rational<Int64>.lowestTerms(narrowNumerator, narrowDenominator) else { return nil }
            return (Integer.Magnitude(narrow.numerator), Integer.Magnitude(narrow.denominator))
        }

        let divisor = greatestCommonDivisor(numerator, denominator)
        guard divisor != 0 else { return nil }
        return (numerator / divisor, denominator / divisor)
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
        guard let reduced = Rational.lowestTerms(numerator.magnitude, denominator.magnitude) else { return }

        // The largest magnitude, one more than `Integer.max`, can only have come from
        // `Integer.min`, which is negative and so takes the negating branch back to `Integer.min`
        // exactly. Every other magnitude is at most `Integer.max`. So neither branch can produce a
        // value `Integer` cannot represent.
        numerator = numerator < 0 ? Integer(truncatingIfNeeded: 0 &- reduced.numerator) : Integer(truncatingIfNeeded: reduced.numerator)
        denominator = denominator < 0 ? Integer(truncatingIfNeeded: 0 &- reduced.denominator) : Integer(truncatingIfNeeded: reduced.denominator)
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

    // Each operation taking a fraction is disfavored against its twin taking an integer, so that an
    // integer literal picks the integer one. For a `Fraction` it would win anyway, as `Int` is a
    // literal's default type, but for a `Fraction128` neither twin's type is, and without this
    // `x.adding(1)` would not compile.

    /// Add another fraction to self.
    /// - Parameters:
    ///   - other: The fraction to add.
    ///   - reducing: A flag indicating whether to reduce the result of the addition to its GCD. Defaults to `true`.
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
    @inlinable @_disfavoredOverload
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
            numerator = try Rational.decodeField(.numerator, from: container)
            denominator = try Rational.decodeField(.denominator, from: container)
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

    /// Encodes each field as a number when it fits in 64 bits, and as a decimal string when it
    /// does not.
    ///
    /// A `Fraction` therefore encodes exactly as it always has, and a `Fraction128` holding an
    /// everyday value encodes exactly as a `Fraction` does, so either can decode the other's data.
    /// A string carries what no 64-bit number can, in JSON and property lists alike, which
    /// matters because `PropertyListEncoder` cannot encode an `Int128` at all.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try Rational.encodeField(numerator, forKey: .numerator, into: &container)
        try Rational.encodeField(denominator, forKey: .denominator, into: &container)
    }

    static func encodeField(_ value: Integer, forKey key: CodingKeys,
                            into container: inout KeyedEncodingContainer<CodingKeys>) throws {
        if let word = Int(exactly: value) {
            try container.encode(word, forKey: key)
        } else if let wide = Int64(exactly: value) {
            // Reached only where `Int` is narrower than 64 bits.
            try container.encode(wide, forKey: key)
        } else {
            try container.encode(String(value), forKey: key)
        }
    }

    /// A field however it was written: as a number the decoder reads natively, as a 64-bit
    /// number, or as a decimal string.
    static func decodeField(_ key: CodingKeys, from container: KeyedDecodingContainer<CodingKeys>) throws -> Integer {
        do {
            return try container.decode(Integer.self, forKey: key)
        } catch let nativeError {
            // Not every decoder reads every width natively, `PropertyListDecoder` has no `Int128`,
            // and a field too wide for 64 bits was encoded as a string.
            if let wide = try? container.decode(Int64.self, forKey: key), let value = Integer(exactly: wide) {
                return value
            }
            if let text = try? container.decode(String.self, forKey: key) {
                guard let value = Integer(text) else {
                    throw DecodingError.dataCorruptedError(forKey: key, in: container,
                                                           debugDescription: "\"\(text)\" is not an integer that fits in \(Integer.self)")
                }
                return value
            }
            throw nativeError
        }
    }
}

// MARK: - Converting between integer types

extension Rational {
    /// A fraction of another integer type as a fraction of this one: with the same fields when
    /// they fit, and otherwise in lowest terms, which may fit where the fields as written did not.
    /// Traps if neither fits; see `init?(exactly:)` to find out first.
    ///
    /// Widening, as from a `Fraction` to a `Fraction128`, always succeeds and keeps the fields as
    /// written.
    @inlinable
    public init<Other>(_ other: Rational<Other>) {
        guard let converted = Rational(exactly: other) else {
            preconditionFailure("\(other) does not fit in a fraction of \(Integer.self)")
        }
        self = converted
    }

    /// A fraction of another integer type as a fraction of this one: with the same fields when
    /// they fit, and otherwise in lowest terms; `nil` if neither fits.
    @inlinable
    public init?<Other>(exactly other: Rational<Other>) {
        if let converted = Rational(fieldsOf: other) {
            self = converted
        } else if let converted = Rational(fieldsOf: other.reduced()) {
            self = converted
        } else {
            return nil
        }
    }

    /// `other`'s fields, unchanged, if both fit in `Integer.min + 1 ... Integer.max`.
    @inlinable
    init?<Other>(fieldsOf other: Rational<Other>) {
        guard let numerator = Integer(exactly: other.numerator), numerator != .min,
              let denominator = Integer(exactly: other.denominator), denominator != .min
        else { return nil }
        self.init(uncheckedNumerator: numerator, denominator: denominator)
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
