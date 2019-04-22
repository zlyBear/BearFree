// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "MMDB",
    products: [
        .library(name: "MMDB", targets: ["MMDB"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "MMDB", dependencies: ["libmaxminddb"]),
        .testTarget(name: "MMDBTests", dependencies: ["MMDB"]),
        .target(name: "libmaxminddb")
    ]
)
