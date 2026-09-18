// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SipApp",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SipApp",
            path: "Sources",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
