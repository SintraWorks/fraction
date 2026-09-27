//
//  Fraction+Conformances.swift
//  Fractions
//
//  Created by Antonio Nunes on 19/09/2026.
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

// MARK: - Hashable

extension Rational: Hashable {
    /// Hashes the fraction's canonical form: reduced to lowest terms, with the sign on the
    /// numerator.
    ///
    /// - Important: The hash **must** be computed on a canonical form, because `==` compares
    ///   the rational values while initialization does not reduce. Equal fractions therefore
    ///   store different fields: `Fraction(numerator: 2, denominator: 4)` equals
    ///   `Fraction(numerator: 1, denominator: 2)`, but the two store `2/4` and `1/2`.
    ///   Synthesized conformance would hash those to different values and so break the
    ///   requirement that equal values hash equally, which in turn would break lookup in any
    ///   `Set` or `Dictionary` keyed by `Fraction`.
    ///
    ///   `==` needs no canonical form of its own — it cross-multiplies, which is
    ///   reduction-invariant — so this is the one operation of the three that still reduces.
    ///
    /// The canonical form is fed to the hasher as two numbers rather than assembled into a
    /// fraction, which avoids the copies `reduced().normalized()` made and keeps the arithmetic
    /// on magnitudes, so a field holding `Integer.min` does not trap.
    @inlinable
    public func hash(into hasher: inout Hasher) {
        // Only 0/0 has no canonical form, and no initializer produces it. Hash it as a constant
        // rather than dividing by zero.
        guard let canonical = Rational.lowestTerms(numerator.magnitude, denominator.magnitude) else {
            hasher.combine(Integer.zero)
            hasher.combine(Integer.Magnitude.zero)
            return
        }

        // A negative sign belongs on the numerator, and zero has no sign, so `0/5` and `0/-5`
        // agree. Negating the largest magnitude, `Integer.max + 1`, lands on `Integer.min`, which
        // is exactly the value a canonical numerator of that size has to take, so this is always
        // representable.
        let isNegative = (numerator < 0) != (denominator < 0)
        hasher.combine(isNegative ? Integer(truncatingIfNeeded: 0 &- canonical.numerator) : Integer(truncatingIfNeeded: canonical.numerator))
        // The canonical denominator is positive by construction, so it is hashed as a magnitude.
        hasher.combine(canonical.denominator)
    }
}

// MARK: - CustomStringConvertible

/// `description` is implemented in `Rational` itself; declaring the conformance here makes
/// `print(_:)` and string interpolation use it, rather than falling back to the reflected
/// representation.
extension Rational: CustomStringConvertible {}
