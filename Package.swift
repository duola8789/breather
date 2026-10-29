// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Breather",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BreatherCore"),
        .executableTarget(name: "Breather", dependencies: ["BreatherCore"]),
        .testTarget(name: "BreatherCoreTests", dependencies: ["BreatherCore"]),
    ]
)
