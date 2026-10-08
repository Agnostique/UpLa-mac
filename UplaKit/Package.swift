// swift-tools-version:5.9
import PackageDescription

// The upla.com.tr client of UpLa for Mac: uploads, the in-app sign-in, response and error parsing, limits and rules.
// No UI and no dependencies; it also builds on Linux (FoundationNetworking) so the tests can run there.
let package = Package(
    name: "UplaKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "UplaKit", targets: ["UplaKit"])
    ],
    targets: [
        .target(name: "UplaKit"),
        .testTarget(name: "UplaKitTests", dependencies: ["UplaKit"])
    ]
)
