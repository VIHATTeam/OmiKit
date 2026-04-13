// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "OmiKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "OmiKit",
            targets: ["OmiKit"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "OmiKit",
            path: "OmiKit.xcframework"
        )
    ]
)
