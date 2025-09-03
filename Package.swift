// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftMLKit",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SegmentationKit", targets: ["SegmentationKit"]),
        .library(name: "MLKitUtilities", targets: ["MLKitUtilities"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MLKitUtilities"
        ),
        .target(
            name: "SegmentationKit",
            dependencies: ["MLKitUtilities"],
            resources: [
                .process("DeepLabV3/DeepLabV3.mlpackage"),
                .process("U2Netp/u2netp.mlmodel")
            ]
        ),
            
        .testTarget(
            name: "SegmentationKitTests",
            dependencies: ["SegmentationKit"]
        ),
    ]
)
