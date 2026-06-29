// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "SwiftCurlCffiIOS",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftCurlCffiIOS",
            targets: ["SwiftCurlCffiIOS"]
        )
    ],
    targets: [
        .target(
            name: "SwiftCurlCffiIOS",
            exclude: ["Resources"]
        )
    ]
)
