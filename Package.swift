// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "lattice-models",
    products: [
        .library(
            name: "lattice-models",
            targets: ["lattice-models"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pumperknickle/Regenerate.git", from: "2.0.2"),
        .package(url: "https://github.com/pumperknickle/CryptoStarterPack.git", from: "1.1.8"),
        .package(url: "https://github.com/pumperknickle/Bedrock.git", from: "0.2.0"),
        .package(url: "https://github.com/pumperknickle/AwesomeDictionary.git", from: "0.0.3"),
        .package(url: "https://github.com/pumperknickle/AwesomeTrie.git", from: "0.1.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "2.1.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "8.0.2"),
        .package(url: "https://github.com/IBM-Swift/BlueSocket.git", from: "1.0.52"),
    ],
    targets: [
        .target(
            name: "lattice-models",
            dependencies: ["Bedrock", "Regenerate", "Socket", "CryptoStarterPack", "AwesomeDictionary", "AwesomeTrie"]),
        .testTarget(
            name: "lattice-modelsTests",
            dependencies: ["lattice-models", "Quick", "Nimble"]),
    ]
)
