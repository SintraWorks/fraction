# Changelog

All notable changes to this package are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

Arithmetic now traps only when its result does not fit in a `Fraction`. It used to trap as soon as
an intermediate product overflowed `Int`, however small the answer: `1/2^40 + 1/2^41` crashed,
although the answer is `3/2^41`. Nothing that worked before returns anything different.

### Fixed

- Addition, subtraction, multiplication and division, of fractions and of integers, no longer trap
  when an intermediate value overflows `Int` but the result fits. Each operation still runs as
  before; only if that overflows does it work the result out exactly, cancelling common factors
  first (Knuth, TAOCP vol. 2, §4.5.1) and carrying the one sum that can outgrow `Int` across two
  words. Every result that did not trap before is unchanged, sign placement included.
- A result that lands on `Int.min`, which is outside the range, now traps in the operation that
  produces it. It used to be returned, only to trap in whatever touched it next:
  `Fraction(verifiedNumerator: -(1 << 62), verifiedDenominator: -1) - Fraction(verifiedNumerator: 1 << 62, verifiedDenominator: -1)`
  is 2^63, which does not fit, yet it returned `Int.min/-1`, and adding 1 to that trapped.
- An integer operand of `Int.min` now works wherever the result fits. Dividing by it, and
  `Int.min - fraction` and `Int.min / fraction`, went through the failable initializer, which
  rejects `Int.min`, and so crashed on a force unwrap whatever the result.
- `nonZeroDivide(by:reducing:)` taking an `Int` ignored `reducing` and always reduced. The
  non-mutating `nonZeroDividing(by:reducing:)` was not affected.
- `init(float:significantDigits:)` accepted up to 18 digits everywhere, but where `Int` is 32 bits
  wide, as on arm64_32 watchOS, 10 to the power 10 already overflows it: 10 to 18 digits passed the
  check and then trapped. The bound now follows the width of `Int`.
- `init(float:significantDigits:)`, and with it every float literal, folded the whole part into the
  numerator as `wholes · 10^n` before reducing, which overflowed for values as small as `1e15`:
  `let x: Fraction = 1e15` crashed. It now traps only on a value whose result does not fit.
- Decoding a `Fraction` from a plain number too large for one, or from NaN, crashed the process
  doing the decoding. It now throws `DecodingError.dataCorrupted`.

### Added

- `maximumSignificantFloatingPointDigits`, the upper bound of `significantDigits`: 18 where `Int` is
  64 bits wide, 9 where it is 32.

- Arithmetic in the `FractionsBenchmarks` target: `+`, `+ Int`, `-`, `*` and `/` on the benchmark
  corpus, and `+` on a corpus whose every sum takes the exact path. Arithmetic that does not
  overflow costs what it did before, to within 2%. The exact path costs about 2.4 times as much,
  and runs only where arithmetic used to trap.
- Property-based tests checking every arithmetic operation, with and without reducing, against the
  1.2.0 formulas evaluated exactly in `Int128`: about 40,000 seeded pairs per operation, weighted
  towards the edges of `Int`.

### Upgrading

Nothing is source-breaking. Three behaviours change, each of them a trap or a bug before:

- Arithmetic that trapped on an intermediate overflow now returns its result.
- A result landing on `Int.min` traps in the operation that produces it, rather than in a later one.
- `nonZeroDivide(by:reducing:)` with an `Int` and `reducing: false` no longer reduces.

## [1.2.0] - 2026-09-21

Comparison and hashing stop reducing, which is where nearly all of their time went. Sorting 350,000
fractions with denominators in the low thousands drops from **480 ms to 42 ms** in a release build,
and building a `Set` of them from **42 ms to 18 ms**.

Nothing about how a `Fraction` stores its numerator and denominator changes: `Fraction(2, 4)` still
remembers itself as `2/4`, and `reducing: false` still means what it meant.

### Changed

- `==` and `<` compare by exact 128-bit cross-multiplication instead of reducing and normalizing
  both operands first. Cross-multiplication is reduction-invariant, so the reduction was never
  needed to get the right answer — it was only keeping the products small, which full-width
  arithmetic does better. Both operators are now total: they contain no division, no negation and
  no truncating multiplication, so they cannot trap on any input.
- `hash(into:)` still canonicalizes, because `==` spans unreduced spellings, but it feeds the
  canonical form to the hasher as two numbers rather than assembling a `Fraction` from
  `reduced().normalized()`. Roughly 30% comes off the part of hashing that is not `Hasher` itself.
- `reduce()` computes over magnitudes rather than negating its way to absolute values.
- Both initializers now range-check `wholes` after folding it into the numerator.

### Fixed

- Comparing two fractions whose cross product exceeds `Int` no longer traps. Reducing first did not
  help when both operands were already in lowest terms, so
  `Fraction(verifiedNumerator: Int.max, verifiedDenominator: 2) < Fraction(verifiedNumerator: Int.max)`
  used to crash.
- `wholes` was folded into the numerator without being checked, so it could smuggle `Int.min` past
  the guards that reject it, and could overflow silently rather than trapping.
  `Fraction(numerator: 0, denominator: 1, wholes: Int.min)` returned a fraction that then trapped on
  first use — on `==`, on `hashValue`, and on every arithmetic operation. It now returns `nil`, and
  the guaranteed initializer traps with a message naming the cause.
- Comparing, hashing or reducing a fraction whose numerator or denominator holds `Int.min` no longer
  traps. The value is outside the type's documented range, but `numerator` and `denominator` are
  writable, so it was reachable regardless of the initializer fix above.
- `reduce()` on `0/0` no longer divides by a zero greatest common divisor. It is left unchanged,
  having no reduced form.

### Added

- A `FractionsBenchmarks` executable target covering sorting, `Set` insertion, reduction, comparison
  and hashing, with controls that expose the floor `Hasher` and `Set` impose. It is deliberately not
  a package product, so it stays invisible to dependents, and it has no dependencies.
- Property-based tests: the new comparison and reduction are checked against inlined copies of the
  1.1.0 implementations over hundreds of thousands of seeded random values, alongside tests for
  scaling invariance and for the order axioms `sort()` relies on.

### Upgrading

Nothing is source-breaking, but three things are worth knowing:

- **Hash values differ from 1.1.0.** They always may between versions — Swift seeds `Hasher` per
  process, so a `hashValue` was never stable across runs either — but do not persist one.
- **Two initializers reject input they used to accept.**
  `Fraction(numerator:denominator:wholes:)` returns `nil` where `wholes` overflows the numerator or
  drives it to `Int.min`; previously it either trapped or produced an unusable value.
- **Comparing a fraction with a zero denominator is now explicitly unspecified.** No initializer
  produces one, but `denominator` is writable. Where 1.1.0 happened to report `5/0` and `-3/0` as
  unequal, they now compare equal, and `0/0` compares equal to everything.

## [1.1.0] - 2026-09-19

Requires **Swift 6.0** or later. Your own package need not declare
`swift-tools-version: 6.0`; a lower tools version works as long as you build with a 6.0 toolchain.

### Added

- `Hashable`, `Sendable` and `CustomStringConvertible` conformances. `Hashable` is written by hand
  rather than synthesized, because equal fractions may store different numerators and denominators
  and so would otherwise hash differently.
- `init(float:significantDigits:)`, choosing conversion precision per call. The valid range is
  0 ... 18, enforced by a precondition; 19 or more overflows `Int` while computing the denominator.

### Changed

- The package moves to `swift-tools-version: 6.0`, putting it in the Swift 6 language mode.

### Removed

- `significantFloatingPointDigits`, a mutable static property, replaced by the immutable
  `defaultSignificantFloatingPointDigits`. **This is a source-breaking change.** The property was
  process-wide state that silently changed the meaning of every float-to-`Fraction` conversion, was
  unsafe to touch from more than one concurrency domain, and had no bounds check. Code that set it
  should pass `significantDigits` to `init(float:significantDigits:)` instead.

## [1.0.1] - 2025-03-20

### Changed

- `License.txt` renamed to `License.md`, so the license renders on GitHub and is recognised by the
  Swift Package Index.

### Added

- Swift Package Index badges for supported Swift versions and platforms.

## [1.0.0] - 2025-03-20

First tagged release, and the first published as a Swift package rather than an Xcode project.

`Fraction` represents the quotient of two integers without loss of precision: addition,
subtraction, multiplication and division, through both named methods and operators, with results
reduced to their greatest common denominator by default and `reducing: false` to opt out.
It conforms to `Comparable`, `Codable`, `ExpressibleByIntegerLiteral` and
`ExpressibleByFloatLiteral`, converts to and from floating-point values, and traps on overflow.

[Unreleased]: https://github.com/SintraWorks/fraction/compare/1.2.0...HEAD
[1.2.0]: https://github.com/SintraWorks/fraction/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/SintraWorks/fraction/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/SintraWorks/fraction/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/SintraWorks/fraction/releases/tag/1.0.0
