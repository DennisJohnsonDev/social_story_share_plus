// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "social_story_share_plus",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "social-story-share-plus", targets: ["social_story_share_plus"])
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "social_story_share_plus",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
