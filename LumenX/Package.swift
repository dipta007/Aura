// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LumenX",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LumenX",
            path: "Sources/LumenX",
            linkerSettings: [
                .unsafeFlags(["-framework", "CoreDisplay"])
            ]
        )
    ]
)
