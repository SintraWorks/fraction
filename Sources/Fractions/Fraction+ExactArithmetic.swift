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

extension Fraction {
    /// Stores the fields as given: for results the arithmetic has already checked, and for
    /// operands no initializer would build, such as an integer of `Int.min` written as a fraction.
    init(uncheckedNumerator numerator: Int, denominator: Int) {
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
    @inline(__always)
    static func sum(_ lhs: Fraction, _ rhs: Fraction, subtracting: Bool, reducing: Bool) -> Fraction? {
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
    @inline(__always)
    static func product(_ lhs: Fraction, _ rhs: Fraction, reducing: Bool) -> Fraction? {
        let (numerator, numeratorOverflow) = lhs.numerator.multipliedReportingOverflow(by: rhs.numerator)
        let (denominator, denominatorOverflow) = lhs.denominator.multipliedReportingOverflow(by: rhs.denominator)
        if !(numeratorOverflow || denominatorOverflow) {
            return finished(numerator, denominator, reducing: reducing)
        }
        return exactProduct(lhs, rhs, reducing: reducing)
    }

    /// Traps on an arithmetic result that no `Fraction` can hold.
    static func trapOverflow(of operation: String, reducing: Bool) -> Never {
        preconditionFailure("Arithmetic overflow: \(operation) does not fit in a Fraction\(reducing ? "" : " without reducing")")
    }

    /// A result the fast path computed without overflowing, reduced if asked.
    ///
    /// No overflow does not yet mean it fits: `Int.min` is representable, but outside the range,
    /// and it is the one value the fast path can land on that the exact path never produces.
    @inline(__always)
    private static func finished(_ numerator: Int, _ denominator: Int, reducing: Bool) -> Fraction? {
        var result = Fraction(uncheckedNumerator: numerator, denominator: denominator)
        if reducing { result.reduce() }
        guard result.numerator != .min, result.denominator != .min else { return nil }
        return result
    }
}

// MARK: - The exact path

extension Fraction {
    /// The exact path of `sum`, taken only when its fast path overflowed.
    @inline(never)
    private static func exactSum(_ lhs: Fraction, _ rhs: Fraction, subtracting: Bool, reducing: Bool) -> Fraction? {
        let sharedDenominator = lhs.denominator == rhs.denominator

        guard reducing else {
            // Unreduced, the result is spelled as the fast path spells it. With a shared
            // denominator its numerator is the very sum that just overflowed, so nothing can be
            // saved. Otherwise a product may have overflowed on the way to a numerator that fits.
            guard !sharedDenominator,
                  let numerator = TwoWords.numerator(lhs.numerator, lhs.denominator,
                                                     rhs.numerator, rhs.denominator,
                                                     subtracting: subtracting)
            else { return nil }
            let (denominator, overflow) = lhs.denominator.multipliedReportingOverflow(by: rhs.denominator)
            guard !overflow, denominator != .min else { return nil }
            return Fraction(uncheckedNumerator: numerator, denominator: denominator)
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
        return Fraction(sum, denominatorIsNegative: denominatorIsNegative)
    }

    /// The exact path of `product`, taken only when its fast path overflowed.
    @inline(never)
    private static func exactProduct(_ lhs: Fraction, _ rhs: Fraction, reducing: Bool) -> Fraction? {
        // Unreduced, the two products are the result, and one of them just overflowed.
        guard reducing, let product = Term.product(Term(lhs), Term(rhs)) else { return nil }
        return Fraction(product, denominatorIsNegative: (lhs.denominator < 0) != (rhs.denominator < 0))
    }

    /// An exact result, signed the way the fast path would have signed it: the denominator
    /// negative when `denominatorIsNegative`, and the numerator whichever way the value then needs.
    private init(_ term: Term, denominatorIsNegative: Bool) {
        // `Term`'s arithmetic returns nil rather than a magnitude above `Int.max`, so both of
        // these convert, and negating them cannot overflow.
        let numerator = Int(term.numerator)
        let denominator = Int(term.denominator)
        self.init(uncheckedNumerator: term.isNegative != denominatorIsNegative ? -numerator : numerator,
                  denominator: denominatorIsNegative ? -denominator : denominator)
    }

    /// A rational value as its sign and the magnitudes of its numerator and denominator.
    ///
    /// Magnitudes reach 2^63, so an `Int.min` integer operand is an ordinary term.
    fileprivate struct Term {
        var isNegative: Bool
        var numerator: UInt
        var denominator: UInt
    }
}

extension Fraction.Term {
    init(_ fraction: Fraction) {
        self.init(isNegative: (fraction.numerator < 0) != (fraction.denominator < 0),
                  numerator: fraction.numerator.magnitude,
                  denominator: fraction.denominator.magnitude)
    }

    /// The same value in lowest terms.
    var reduced: Fraction.Term {
        let divisor = Fraction.greatestCommonDivisor(numerator, denominator)
        guard divisor > 1 else { return self }
        return Fraction.Term(isNegative: isNegative, numerator: numerator / divisor, denominator: denominator / divisor)
    }

    /// `x + y` in lowest terms, or `nil` if either of its magnitudes exceeds `Int.max`.
    ///
    /// Knuth's addition (TAOCP vol. 2, §4.5.1). With `x` and `y` in lowest terms, the only
    /// factors the numerator sum can share with the denominator are factors of `d1`, the
    /// denominators' greatest common divisor; dividing out `d2`, the part it does share, leaves
    /// the result in lowest terms. Everything stays within one word except that numerator sum,
    /// which is carried across two.
    static func sum(_ x: Fraction.Term, _ y: Fraction.Term) -> Fraction.Term? {
        let x = x.reduced
        let y = y.reduced

        let d1 = Fraction.greatestCommonDivisor(x.denominator, y.denominator)
        // Only two zero denominators, which no initializer produces, have no divisor to share.
        guard d1 != 0 else { return nil }
        let xScale = y.denominator / d1
        let yScale = x.denominator / d1

        // Neither product exceeds 2^126, so their sum or difference fits in two words.
        let t = TwoWords.signedSum(x.numerator.multipliedFullWidth(by: xScale), negative: x.isNegative,
                                   y.numerator.multipliedFullWidth(by: yScale), negative: y.isNegative)

        // d2 = gcd(t, d1), reached through t mod d1 so that it takes a single word.
        let remainder = d1.dividingFullWidth((high: t.magnitude.high % d1, low: t.magnitude.low)).remainder
        let d2 = Fraction.greatestCommonDivisor(remainder, d1)

        // A quotient fits in one word exactly when the dividend's high word is below the divisor.
        guard t.magnitude.high < d2 else { return nil }
        let numerator = d2.dividingFullWidth(t.magnitude).quotient
        let (denominator, overflow) = yScale.multipliedReportingOverflow(by: y.denominator / d2)
        guard numerator <= UInt(Int.max), !overflow, denominator <= UInt(Int.max) else { return nil }

        return Fraction.Term(isNegative: t.isNegative, numerator: numerator, denominator: denominator)
    }

    /// `x * y` in lowest terms, or `nil` if either of its magnitudes exceeds `Int.max`.
    ///
    /// Each numerator is cancelled against the other operand's denominator before multiplying
    /// (TAOCP vol. 2, §4.5.1). With `x` and `y` in lowest terms, what remains shares no factor, so
    /// the products are the result in lowest terms, and neither is wider than the result.
    static func product(_ x: Fraction.Term, _ y: Fraction.Term) -> Fraction.Term? {
        let x = x.reduced
        let y = y.reduced

        // A greatest common divisor is 0 only when both arguments are, and dividing 0 by 1 is
        // as good as dividing it by anything.
        let g1 = Swift.max(Fraction.greatestCommonDivisor(x.numerator, y.denominator), 1)
        let g2 = Swift.max(Fraction.greatestCommonDivisor(y.numerator, x.denominator), 1)

        let (numerator, numeratorOverflow) = (x.numerator / g1).multipliedReportingOverflow(by: y.numerator / g2)
        let (denominator, denominatorOverflow) = (x.denominator / g2).multipliedReportingOverflow(by: y.denominator / g1)
        guard !numeratorOverflow, !denominatorOverflow,
              numerator <= UInt(Int.max), denominator <= UInt(Int.max) else { return nil }

        return Fraction.Term(isNegative: x.isNegative != y.isNegative, numerator: numerator, denominator: denominator)
    }
}

// MARK: - Two-word magnitudes

/// The one quantity in the exact path that can outgrow a word — a sum of two full-width
/// products — kept as a magnitude two words wide, with its sign alongside.
private enum TwoWords {
    typealias Magnitude = (high: UInt, low: UInt)

    /// `±p ± q`, as a magnitude and a sign.
    ///
    /// The callers' operands are products of two magnitudes of at most 2^63 each, so their sum
    /// stays within 2^127 and cannot carry out of the high word.
    static func signedSum(_ p: Magnitude, negative pIsNegative: Bool,
                          _ q: Magnitude, negative qIsNegative: Bool) -> (magnitude: Magnitude, isNegative: Bool) {
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

    /// `a·d + c·b`, or `a·d - c·b` when `subtracting` — the numerator the fast path forms for
    /// `a/b ± c/d` — computed exactly; `nil` if it falls outside `Int.min + 1 ... Int.max`.
    static func numerator(_ a: Int, _ b: Int, _ c: Int, _ d: Int, subtracting: Bool) -> Int? {
        let sum = signedSum(a.magnitude.multipliedFullWidth(by: d.magnitude), negative: (a < 0) != (d < 0),
                            c.magnitude.multipliedFullWidth(by: b.magnitude), negative: ((c < 0) != (b < 0)) != subtracting)
        guard sum.magnitude.high == 0, sum.magnitude.low <= UInt(Int.max) else { return nil }

        let magnitude = Int(sum.magnitude.low)
        return sum.isNegative ? -magnitude : magnitude
    }
}
