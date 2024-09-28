// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "JSWheel",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "JSWheel",
            targets: ["JSWheel"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/wlsdms0122/Stylish.git", from: "3.0.1")
    ],
    targets: [
        .target(
            name: "JSWheel",
            dependencies: [
                "Stylish"
            ]
        ),
        .testTarget(
            name: "JSWheelTests",
            dependencies: [
                "JSWheel"
            ]
        )
    ]
)
