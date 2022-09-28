// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IssueKit",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "issue", targets: ["IssueKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "IssueKit",
            dependencies: [
                .product(
                    name: "ArgumentParser",
                    package: "swift-argument-parser"
                ),
                "IssueKitCore"
            ]
        ),
        .target(name: "IssueKitCore")
    ]
)
