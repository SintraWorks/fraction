// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Fractions",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Fractions",
            targets: ["Fractions"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Fractions"),
        .testTarget(
            name: "FractionsTests",
            dependencies: ["Fractions"]
        ),
        // A local benchmark for Fraction's hot path. It is deliberately not exposed as a
        // product, so it stays invisible to anything that depends on this package, and it must
        // never gain a package dependency: the manifest's empty dependency graph would
        // otherwise propagate into every dependent's Package.resolved.
        .executableTarget(
            name: "FractionsBenchmarks",
            dependencies: ["Fractions"]
        ),
    ]
)
