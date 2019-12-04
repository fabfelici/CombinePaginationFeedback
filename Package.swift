// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombinePaginationFeedback",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v13),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "CombinePaginationFeedback",
            targets: ["CombinePaginationFeedback"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/sergdort/CombineFeedback.git", .branch("master")),
        .package(url: "https://github.com/mluisbrown/Thresher.git", .branch("master"))
    ],
    targets: [
        .target(
            name: "CombinePaginationFeedback",
            dependencies: ["CombineFeedback"]
        ),
        .testTarget(
            name: "CombinePaginationFeedbackTests",
            dependencies: ["CombinePaginationFeedback", "CombineFeedback", "Thresher"]
        ),
    ]
)

