// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClipVault",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "ClipVault",
            path: "Sources/ClipVault",
            linkerSettings: [
                .linkedFramework("Carbon"),
                .linkedFramework("AppKit"),
                .linkedFramework("CoreGraphics"),
            ]
        )
    ]
)
