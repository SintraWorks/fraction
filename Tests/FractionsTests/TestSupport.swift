//
//  TestSupport.swift
//  FractionsTests
//
//  Copyright © 2026 SintraWorks.
//
//  Shared helpers for the randomised tests. See License.md for the license text.

@testable import Fractions

/// SplitMix64: a seeded generator, so a randomised test that fails fails again on the next run.
///
/// `SystemRandomNumberGenerator` would make failures unreproducible, which is the one thing a
/// property test cannot afford.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension SplitMix64 {
    /// A fraction whose numerator and denominator magnitudes are at most `bound`, in all four
    /// sign combinations. The denominator is never zero; the numerator sometimes is.
    mutating func nextFraction(bound: Int) -> Fraction {
        let numeratorMagnitude = Int.random(in: 0 ... bound, using: &self)
        let denominatorMagnitude = Int.random(in: 1 ... bound, using: &self)
        let negativeNumerator = Bool.random(using: &self)
        let negativeDenominator = Bool.random(using: &self)

        return Fraction(verifiedNumerator: negativeNumerator ? -numeratorMagnitude : numeratorMagnitude,
                        verifiedDenominator: negativeDenominator ? -denominatorMagnitude : denominatorMagnitude)
    }
}

/// Builds a fraction with fields no initializer would accept.
///
/// `numerator` and `denominator` are writable, so out-of-domain values are reachable even though
/// nothing constructs them. Tests that pin down what happens there need a way to get there.
func unchecked(_ numerator: Int, _ denominator: Int) -> Fraction {
    var fraction = Fraction(verifiedNumerator: 1, verifiedDenominator: 1)
    fraction.numerator = numerator
    fraction.denominator = denominator
    return fraction
}
