// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExampleUsage",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "ExampleUsage",
            dependencies: [
                .product(name: "ConcurrencyPrimitives", package: "ThreadPool"),
                .product(name: "ThreadPool", package: "ThreadPool")
            ],
            path: "Sources/")
    ]
)
