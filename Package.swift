// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KaleidoscopeEngine",
    platforms: [.iOS(.v13), .macOS(.v10_15),],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KaleidoscopeEngine",
            targets: ["KaleidoscopeEngine"]),
        
            .library(
                name: "VideoKaleidoscopeEngine",
                targets: ["VideoKaleidoscopeEngine"]),
        
        .executable(name: "GenerateImage", targets: ["GenerateImage"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KaleidoscopeEngine"),
        
        .target(
            name: "VideoKaleidoscopeEngine",
            dependencies: ["KaleidoscopeEngine"]),
        
        .testTarget(
            name: "KaleidoscopeEngineTests",
            dependencies: ["KaleidoscopeEngine"]),
        
        .executableTarget(name: "GenerateImage", dependencies: ["KaleidoscopeEngine"])
    ]
)
