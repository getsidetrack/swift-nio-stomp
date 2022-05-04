// swift-tools-version: 5.6
import PackageDescription

let package = Package(
    name: "swift-nio-stomp",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        .library(name: "NIOSTOMP", targets: ["NIOSTOMP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.23.0"),
        .package(url: "https://github.com/apple/swift-metrics.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "NIOSTOMP",
            dependencies: [
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Metrics", package: "swift-metrics"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources"
        ),
        
        .testTarget(
            name: "NIOSTOMPTests",
            dependencies: [
                .target(name: "NIOSTOMP"),
            ],
            path: "Tests"
        ),
    ]
)
