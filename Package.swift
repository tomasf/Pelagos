// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Pelagos",
    platforms: [.macOS(.v10_15)],
    products: [
        .library(name: "Pelagos", targets: ["Pelagos"])
    ],
    dependencies: [
        .package(url: "https://github.com/tomasf/Nodal.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "Pelagos",
            dependencies: ["Nodal"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "PelagosTests",
            dependencies: ["Pelagos"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ]
)
