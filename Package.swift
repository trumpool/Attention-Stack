// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AttentionStack",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "AttentionStack", targets: ["AttentionStack"])],
    targets: [
        .target(name: "AttentionCore"),
        .executableTarget(name: "AttentionStack", dependencies: ["AttentionCore"]),
        .testTarget(name: "AttentionCoreTests", dependencies: ["AttentionCore"])
    ],
    swiftLanguageModes: [.v6]
)
