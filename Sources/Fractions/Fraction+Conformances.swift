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

extension Fraction: Hashable {
    /// Hashes the fraction's canonical (reduced, normalized) form.
    ///
    /// - Important: The hash **must** be computed on the same form that `==` compares,
    ///   and `==` compares `reduced().normalized()`. Since initialization does not reduce,
    ///   equal fractions may store different values: `Fraction(numerator: 2, denominator: 4)`
    ///   equals `Fraction(numerator: 1, denominator: 2)`, but the two store `2/4` and `1/2`
    ///   respectively. Synthesized conformance would hash those to different values and so
    ///   break the requirement that equal values hash equally, which in turn would break
    ///   lookup in any `Set` or `Dictionary` keyed by `Fraction`.
    public func hash(into hasher: inout Hasher) {
        let canonical = reduced().normalized()
        hasher.combine(canonical.numerator)
        hasher.combine(canonical.denominator)
    }
}

// MARK: - CustomStringConvertible

/// `description` is implemented in `Fraction` itself; declaring the conformance here makes
/// `print(_:)` and string interpolation use it, rather than falling back to the reflected
/// representation.
extension Fraction: CustomStringConvertible {}
