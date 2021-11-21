// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "speck",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .executable(
            name: "speck",
            targets: ["speck"]),
        .library(
            name: "CoreSpeck",
            targets: ["CoreSpeck"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "Yams", url: "https://github.com/jpsim/Yams", .upToNextMajor(from: "4.0.6")),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax", from: "0.50500.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "speck",
            dependencies: ["CoreSpeck", "SwiftSyntax"]),
        .target(
            name: "CoreSpeck",
            dependencies: ["Yams"]),
        .testTarget(
            name: "speckTests",
            dependencies: ["speck"]),
    ]
)
