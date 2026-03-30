// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slideshow",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Slideshow", targets: ["Slideshow"])
    ],
    targets: [
        .target(
            name: "SlideshowCore",
            path: "Sources/SlideshowCore"
        ),
        .executableTarget(
            name: "Slideshow",
            dependencies: ["SlideshowCore"],
            path: "Sources/Slideshow"
        ),
        .testTarget(
            name: "SlideshowTests",
            dependencies: ["SlideshowCore"],
            path: "Tests/SlideshowTests"
        )
    ]
)
