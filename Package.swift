// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThreadPool",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(name: "ConcurrencyPrimitives", targets: ["ConcurrencyPrimitives"]),
        .library(
            name: "ThreadPool",
            targets: ["ThreadPool"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ThreadPool", dependencies: ["ConcurrencyPrimitives"]),
        .target(name: "ConcurrencyPrimitives"),
        .testTarget(
            name: "ThreadPoolTests",
            dependencies: ["ConcurrencyPrimitives", "ThreadPool"], path: "Tests")
    ]
)
