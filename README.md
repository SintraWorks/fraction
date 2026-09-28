# Fraction

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSintraWorks%2Ffraction%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/SintraWorks/fraction)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSintraWorks%2Ffraction%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/SintraWorks/fraction)

Fraction is a value type that represents the quotient of two numbers (like `1/3`), without loss of precision, and with support for basic arithmetic operations.

The Fraction type supports **addition**, **subtraction**, **multiplication** and **division**, both through dedicated functions, and through overloading the corresponding operators. It also conforms to the **Comparable** protocol to allow comparing fractions and testing them for equality, and to **Hashable**, **Codable** and **Sendable**.

Comparison is by value, not by spelling: a fraction remembers how it was written, so `Fraction(numerator: 2, denominator: 4)` stores `2/4`, but it compares equal to `1/2` and hashes alike, which makes either usable as the same `Dictionary` key or `Set` member.

    Per example, you can add two fractions in any of the following ways:

        var f1 = Fraction(numerator: 1, denominator: 2)
        let f2 = Fraction(numerator: 3, denominator: 4)

        f1.add(f2) // mutating, f1 now holds the result of the addition
        let result1 = f1.adding(f2) // non-mutating
        let result2 = f1 + f2 // non-mutating
        f1 += f2 // mutating, f1 now holds the result of the addition

By default arithmetic operations will reduce the result to its **Greatest Common Denominator**. The function based variants allow turning off this behaviour by explicitly forbidding reduction:

        f1.add(f2, reducing: false)

Arithmetic on a Fraction traps only when its result does not fit: when the result's numerator or denominator falls outside `Int.min + 1 ... Int.max`. Results are in lowest terms unless you pass `reducing: false`, and then it is the unreduced result that has to fit. Intermediate values never cause a trap: `1/2^40 + 1/2^41` is `3/2^41`, although the product of the two denominators is far beyond `Int`. Comparing and hashing fractions never trap either: they carry their products at full width.

Release-by-release changes are recorded in [CHANGELOG.md](CHANGELOG.md).

## Fractions beyond 64 bits

A `Fraction` holds numerators and denominators of up to 63 bits. For results that outgrow that, use a `Fraction128`, which holds up to 127 bits in each and otherwise works exactly as a `Fraction` does:

    let largest: Fraction128 = 170141183460469231731687303715884105727   // Int128.max
    let third = Fraction128(verifiedNumerator: 1, verifiedDenominator: 3)
    let product = largest * third

Both are the same generic type, `Rational`, over different integers: `Fraction` is `Rational<Int>`, and `Fraction128` is `Rational<Int128>`. A `Fraction128` needs Swift's `Int128`, and so macOS 15, iOS 18, watchOS 11, tvOS 18 or visionOS 2; on Linux it is always available. A `Fraction` works everywhere it always has.

Convert between the two with `init(_:)`, which traps if the value does not fit, or `init?(exactly:)`, which returns `nil` instead. Widening always fits, and keeps the fields as written:

    let wide = Fraction128(fraction)                 // always succeeds
    let narrow = Fraction(exactly: wideFraction)      // nil if the value does not fit

Encoded, a `Fraction128` writes each field as a number when it fits in 64 bits, exactly as a `Fraction` does, and as a decimal string when it does not. So either type decodes the other's data wherever the values fit, and both JSON and property lists can carry any `Fraction128`; `PropertyListEncoder` cannot encode an `Int128` itself.

A `Fraction128` holding everyday values costs 1.2 to 1.4 times what a `Fraction` does, and comparing costs twice as much. Arithmetic whose results reach well past 64 bits costs more, six to seven times as much as everyday arithmetic on a `Fraction` in the package's benchmark, as 128-bit division runs in software.

## Using **Fractions** in your project

Fractions requires **Swift 6.0** or later.

To use this package in a SwiftPM project, you need to set it up as a package dependency:

```swift
// swift-tools-version:6.0
import PackageDescription

let package = Package(
  name: "MyPackage",
  dependencies: [
    .package(
      url: "https://github.com/sintraworks/fraction.git",
      .upToNextMinor(from: "1.2.0") // or .upToNextMajor
    )
  ],
  targets: [
    .target(
      name: "MyTarget",
      dependencies: [
        .product(name: "Fractions", package: "fraction")
      ]
    )
  ]
)
```

Your own package does not have to declare `swift-tools-version: 6.0`. A lower tools version works, as long as you build with a Swift 6.0 or later toolchain. Declaring 6.0 does, however, opt your own package into the Swift 6 language mode.
