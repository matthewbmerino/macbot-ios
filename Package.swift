// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MacbotMobile",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
    ],
    targets: [
        .executableTarget(
            name: "MacbotMobile",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
            ],
            path: "MacbotMobile"
        ),
    ]
)
