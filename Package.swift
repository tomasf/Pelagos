// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Pelagos",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(name: "Pelagos", targets: ["Pelagos"]),
        .executable(name: "PelagosCLI", targets: ["PelagosCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/tomasf/Nodal.git", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "Pelagos",
            dependencies: ["Nodal"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "PelagosCLI",
            dependencies: ["Pelagos"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "PelagosTests",
            dependencies: ["Pelagos"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ]
)
