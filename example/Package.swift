// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "ExampleApp",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    dependencies: [
        .package(path: "..")
    ],
    targets: [
        .executableTarget(
            name: "ExampleApp",
            dependencies: ["XCUIDebug"]
        )
    ]
)
