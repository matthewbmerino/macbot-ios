// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "iPhoneBot",
    platforms: [.iOS(.v17), .macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift", from: "7.0.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/pgorzelany/swift-llama-cpp", from: "1.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "MacbotMobile",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "SwiftLlama", package: "swift-llama-cpp"),
            ],
            path: "MacbotMobile",
            swiftSettings: [
                .interoperabilityMode(.Cxx),
            ]
        ),
    ]
)
