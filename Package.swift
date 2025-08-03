// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "XCUIDebug",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "XCUIDebug",
            targets: ["XCUIDebug"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "XCUIDebug",
            path: "Sources/XCUIDebug"
        )
    ],
    swiftLanguageVersions: [.v5]
)
