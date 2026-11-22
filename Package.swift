// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Stinsen",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(name: "Stinsen", targets: ["Stinsen"])
    ],
    targets: [
        .target(
            name: "Stinsen",
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        ),
        .testTarget(
            name: "StinsenTests",
            dependencies: ["Stinsen"],
            swiftSettings: [
                .defaultIsolation(MainActor.self)
            ]
        )
    ]
)
