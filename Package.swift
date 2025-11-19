// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "Stinsen",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v7)
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
        )
    ]
)
