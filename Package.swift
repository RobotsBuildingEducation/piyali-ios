// swift-tools-version: 5.10
import PackageDescription
let package = Package(name: "PiyaliCore", platforms: [.macOS(.v14), .iOS(.v17)], products: [.library(name: "PiyaliCore", targets: ["PiyaliCore"])], targets: [
    .target(name: "PiyaliCore", path: "Piyali/Core", linkerSettings: [.linkedLibrary("z")]),
    .testTarget(name: "PiyaliCoreTests", dependencies: ["PiyaliCore"], path: "Tests/PiyaliCoreTests")
])
