// swift-tools-version: 5.9
// NOTE: This Package.swift is for reference. The primary build system is Xcode (project.yml → .xcodeproj via XcodeGen).
// To build: install XcodeGen (`brew install xcodegen`), then run `xcodegen generate`

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
            exclude: ["Info.plist", "Sip.entitlements"],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
