// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Pelagos",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6)],
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
