//
//  Fraction+ExactArithmetic.swift
//  Fractions
//
//  Created by Antonio Nunes on 27/09/2026.
//  Copyright © 2026 SintraWorks.
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

// MARK: - Arithmetic that overflows only when its result does
//
// Everything here is `@inlinable`, like the operations that call it. A generic function called
// from another module runs unspecialized unless its body is visible there, and unspecialized
// arithmetic over `Integer` is an order of magnitude slower than the specialized kind.

extension Rational {
    /// Stores the fields as given: for results the arithmetic has already checked, and for
    /// operands no initializer would build, such as an integer of `Integer.min` written as a
    /// fraction.
    @inlinable
    init(uncheckedNumerator numerator: Integer, denominator: Integer) {
        self.numerator = numerator
        self.denominator = denominator
    }

    /// `lhs + rhs`, or `lhs - rhs` when `subtracting`, spelled exactly as `add` and `subtract`
    /// have always spelled it; `nil` if that result does not fit.
    ///
    /// The fast path below is the arithmetic this type has always done, with overflow reported
    /// instead of trapped on. It is what runs whenever nothing overflows, so none of those results
    /// change. Only when it does overflow does the exact path take over, to find out whether the
    /// result itself is too large or merely a step on the way to it was.
    @inlinable @inline(__always)
    static func sum(_ lhs: Rational, _ rhs: Rational, subtracting: Bool, reducing: Bool) -> Rational? {
        if lhs.denominator == rhs.denominator {
            let (numerator, overflow) = subtracting
                ? lhs.numerator.subtractingReportingOverflow(rhs.numerator)
                : lhs.numerator.addingReportingOverflow(rhs.numerator)
            if !overflow { return finished(numerator, lhs.denominator, reducing: reducing) }
        } else {
            let (ad, adOverflow) = lhs.numerator.multipliedReportingOverflow(by: rhs.denominator)
            let (cb, cbOverflow) = rhs.numerator.multipliedReportingOverflow(by: lhs.denominator)
            let (numerator, numeratorOverflow) = subtracting
                ? ad.subtractingReportingOverflow(cb)
                : ad.addingReportingOverflow(cb)
            let (denominator, denominatorOverflow) = lhs.denominator.multipliedReportingOverflow(by: rhs.denominator)
            if !(adOverflow || cbOverflow || numeratorOverflow || denominatorOverflow) {
                return finished(numerator, denominator, reducing: reducing)
            }
        }
        return exactSum(lhs, rhs, subtracting: subtracting, reducing: reducing)
    }

    /// `lhs * rhs`, spelled exactly as `multiply` has always spelled it; `nil` if that result does
    /// not fit. Division comes here too, with the divisor's fields swapped.
    ///
    /// As with `sum`, the fast path is the original arithmetic, and the exact path runs only when
    /// it overflows.
    @inlinable @inline(__always)
    static func product(_ lhs: Rational, _ rhs: Rational, reducing: Bool) -> Rational? {
        let (numerator, numeratorOverflow) = lhs.numerator.multipliedReportingOverflow(by: rhs.numerator)
        let (denominator, denominatorOverflow) = lhs.denominator.multipliedReportingOverflow(by: rhs.denominator)
        if !(numeratorOverflow || denominatorOverflow) {
            return finished(numerator, denominator, reducing: reducing)
        }
        return exactProduct(lhs, rhs, reducing: reducing)
    }

    /// Traps on an arithmetic result that no fraction of `Integer` can hold.
    @usableFromInline
    static func trapOverflow(of operation: String, reducing: Bool) -> Never {
        preconditionFailure("Arithmetic overflow: \(operation) does not fit in a fraction of \(Integer.self)\(reducing ? "" : " without reducing")")
    }

    /// A result the fast path computed without overflowing, reduced if asked.
    ///
    /// No overflow does not yet mean it fits: `Integer.min` is representable, but outside the
    /// range, and it is the one value the fast path can land on that the exact path never
    /// produces.
    @inlinable @inline(__always)
    static func finished(_ numerator: Integer, _ denominator: Integer, reducing: Bool) -> Rational? {
        var result = Rational(uncheckedNumerator: numerator, denominator: denominator)
        if reducing { result.reduce() }
        guard result.numerator != .min, result.denominator != .min else { return nil }
        return result
    }
}

// MARK: - The exact path

extension Rational {
    /// The exact path of `sum`, taken only when its fast path overflowed.
    @inlinable @inline(never)
    static func exactSum(_ lhs: Rational, _ rhs: Rational, subtracting: Bool, reducing: Bool) -> Rational? {
        let sharedDenominator = lhs.denominator == rhs.denominator

        guard reducing else {
            // Unreduced, the result is spelled as the fast path spells it. With a shared
            // denominator its numerator is the very sum that just overflowed, so nothing can be
            // saved. Otherwise a product may have overflowed on the way to a numerator that fits.
            guard !sharedDenominator,
                  let numerator = exactNumerator(lhs.numerator, lhs.denominator,
                                                 rhs.numerator, rhs.denominator,
                                                 subtracting: subtracting)
            else { return nil }
            let (denominator, overflow) = lhs.denominator.multipliedReportingOverflow(by: rhs.denominator)
            guard !overflow, denominator != .min else { return nil }
            return Rational(uncheckedNumerator: numerator, denominator: denominator)
        }

        var right = Term(rhs)
        if subtracting { right.isNegative.toggle() }
        guard let sum = Term.sum(Term(lhs), right) else { return nil }

        // The fast path's denominator is either the shared one or the product of both, and
        // reducing leaves its sign in place. The exact result takes the same sign, so where it
        // lands does not depend on whether anything overflowed.
        let denominatorIsNegative = sharedDenominator
            ? lhs.denominator < 0
            : (lhs.denominator < 0) != (rhs.denominator < 0)
        return Rational(sum, denominatorIsNegative: denominatorIsNegative)
    }

    /// The exact path of `product`, taken only when its fast path overflowed.
    @inlinable @inline(never)
    static func exactProduct(_ lhs: Rational, _ rhs: Rational, reducing: Bool) -> Rational? {
        // Unreduced, the two products are the result, and one of them just overflowed.
        guard reducing, let product = Term.product(Term(lhs), Term(rhs)) else { return nil }
        return Rational(product, denominatorIsNegative: (lhs.denominator < 0) != (rhs.denominator < 0))
    }

    /// `a·d + c·b`, or `a·d - c·b` when `subtracting` — the numerator the fast path forms for
    /// `a/b ± c/d` — computed exactly; `nil` if it falls outside `Integer.min + 1 ... Integer.max`.
    @inlinable
    static func exactNumerator(_ a: Integer, _ b: Integer, _ c: Integer, _ d: Integer, subtracting: Bool) -> Integer? {
        let sum = TwoWords<Integer.Magnitude>.signedSum(
            a.magnitude.multipliedFullWidth(by: d.magnitude), negative: (a < 0) != (d < 0),
            c.magnitude.multipliedFullWidth(by: b.magnitude), negative: ((c < 0) != (b < 0)) != subtracting)
        guard sum.magnitude.high == 0, sum.magnitude.low <= Integer.max.magnitude else { return nil }

        let magnitude = Integer(sum.magnitude.low)
        return sum.isNegative ? -magnitude : magnitude
    }

    /// An exact result, signed the way the fast path would have signed it: the denominator
    /// negative when `denominatorIsNegative`, and the numerator whichever way the value then needs.
    @inlinable
    init(_ term: Term, denominatorIsNegative: Bool) {
        // `Term`'s arithmetic returns nil rather than a magnitude above `Integer.max`, so both of
        // these convert, and negating them cannot overflow.
        let numerator = Integer(term.numerator)
        let denominator = Integer(term.denominator)
        self.init(uncheckedNumerator: term.isNegative != denominatorIsNegative ? -numerator : numerator,
                  denominator: denominatorIsNegative ? -denominator : denominator)
    }

    /// A rational value as its sign and the magnitudes of its numerator and denominator.
    ///
    /// Magnitudes reach `Integer.max + 1`, so an `Integer.min` integer operand is an ordinary term.
    @usableFromInline
    struct Term {
        @usableFromInline var isNegative: Bool
        @usableFromInline var numerator: Integer.Magnitude
        @usableFromInline var denominator: Integer.Magnitude

        @inlinable
        init(isNegative: Bool, numerator: Integer.Magnitude, denominator: Integer.Magnitude) {
            self.isNegative = isNegative
            self.numerator = numerator
            self.denominator = denominator
        }
    }
}

extension Rational.Term {
    @inlinable
    init(_ fraction: Rational) {
        self.init(isNegative: (fraction.numerator < 0) != (fraction.denominator < 0),
                  numerator: fraction.numerator.magnitude,
                  denominator: fraction.denominator.magnitude)
    }

    /// The same value in lowest terms.
    @inlinable
    var reduced: Rational.Term {
        let divisor = Rational.greatestCommonDivisor(numerator, denominator)
        guard divisor > 1 else { return self }
        return Rational.Term(isNegative: isNegative, numerator: numerator / divisor, denominator: denominator / divisor)
    }

    /// `x + y` in lowest terms, or `nil` if either of its magnitudes exceeds `Integer.max`.
    ///
    /// Knuth's addition (TAOCP vol. 2, §4.5.1). With `x` and `y` in lowest terms, the only
    /// factors the numerator sum can share with the denominator are factors of `d1`, the
    /// denominators' greatest common divisor; dividing out `d2`, the part it does share, leaves
    /// the result in lowest terms. Everything stays within one word except that numerator sum,
    /// which is carried across two.
    @inlinable
    static func sum(_ x: Rational.Term, _ y: Rational.Term) -> Rational.Term? {
        let x = x.reduced
        let y = y.reduced

        let d1 = Rational.greatestCommonDivisor(x.denominator, y.denominator)
        // Only two zero denominators, which no initializer produces, have no divisor to share.
        guard d1 != 0 else { return nil }
        let xScale = y.denominator / d1
        let yScale = x.denominator / d1

        // Each product has factors of at most half the two-word range, so their sum or
        // difference fits in two words.
        let t = TwoWords<Integer.Magnitude>.signedSum(
            x.numerator.multipliedFullWidth(by: xScale), negative: x.isNegative,
            y.numerator.multipliedFullWidth(by: yScale), negative: y.isNegative)

        // d2 = gcd(t, d1), reached through t mod d1 so that it takes a single word.
        let remainder = d1.dividingFullWidth((high: t.magnitude.high % d1, low: t.magnitude.low)).remainder
        let d2 = Rational.greatestCommonDivisor(remainder, d1)

        // A quotient fits in one word exactly when the dividend's high word is below the divisor.
        guard t.magnitude.high < d2 else { return nil }
        let numerator = d2.dividingFullWidth(t.magnitude).quotient
        let (denominator, overflow) = yScale.multipliedReportingOverflow(by: y.denominator / d2)
        guard numerator <= Integer.max.magnitude, !overflow, denominator <= Integer.max.magnitude else { return nil }

        return Rational.Term(isNegative: t.isNegative, numerator: numerator, denominator: denominator)
    }

    /// `x * y` in lowest terms, or `nil` if either of its magnitudes exceeds `Integer.max`.
    ///
    /// Each numerator is cancelled against the other operand's denominator before multiplying
    /// (TAOCP vol. 2, §4.5.1). With `x` and `y` in lowest terms, what remains shares no factor, so
    /// the products are the result in lowest terms, and neither is wider than the result.
    @inlinable
    static func product(_ x: Rational.Term, _ y: Rational.Term) -> Rational.Term? {
        let x = x.reduced
        let y = y.reduced

        // A greatest common divisor is 0 only when both arguments are, and dividing 0 by 1 is
        // as good as dividing it by anything.
        let g1 = Swift.max(Rational.greatestCommonDivisor(x.numerator, y.denominator), 1)
        let g2 = Swift.max(Rational.greatestCommonDivisor(y.numerator, x.denominator), 1)

        let (numerator, numeratorOverflow) = (x.numerator / g1).multipliedReportingOverflow(by: y.numerator / g2)
        let (denominator, denominatorOverflow) = (x.denominator / g2).multipliedReportingOverflow(by: y.denominator / g1)
        guard !numeratorOverflow, !denominatorOverflow,
              numerator <= Integer.max.magnitude, denominator <= Integer.max.magnitude else { return nil }

        return Rational.Term(isNegative: x.isNegative != y.isNegative, numerator: numerator, denominator: denominator)
    }
}

// MARK: - Two-word magnitudes

/// The one quantity in the exact path that can outgrow a word — a sum of two full-width
/// products — kept as a magnitude two words wide, the form `multipliedFullWidth(by:)` returns
/// and `dividingFullWidth(_:)` takes, with its sign alongside.
@usableFromInline
enum TwoWords<Word: FixedWidthInteger & UnsignedInteger> {
    /// `±p ± q`, as a magnitude and a sign.
    ///
    /// The callers' operands are products of two magnitudes of at most half the range each, so
    /// their sum stays within the two-word range and cannot carry out of the high word.
    @inlinable
    static func signedSum(_ p: (high: Word, low: Word.Magnitude), negative pIsNegative: Bool,
                          _ q: (high: Word, low: Word.Magnitude), negative qIsNegative: Bool)
        -> (magnitude: (high: Word, low: Word.Magnitude), isNegative: Bool) {
        if pIsNegative == qIsNegative {
            let (low, carry) = p.low.addingReportingOverflow(q.low)
            return ((p.high + q.high + (carry ? 1 : 0), low), pIsNegative)
        }

        // Opposite signs: the smaller magnitude comes off the larger, whose sign the result keeps.
        let (larger, smaller, isNegative) = (p.high, p.low) >= (q.high, q.low)
            ? (p, q, pIsNegative)
            : (q, p, qIsNegative)
        let (low, borrow) = larger.low.subtractingReportingOverflow(smaller.low)
        return ((larger.high - smaller.high - (borrow ? 1 : 0), low), isNegative)
    }
}
