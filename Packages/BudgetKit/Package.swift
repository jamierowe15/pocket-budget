// swift-tools-version: 6.0
import PackageDescription

// BudgetKit holds the app's rules: money, months, budget maths, CSV export and the data the
// widget shows. Foundation only, Swift 6 language mode (full data-race checking), so it
// builds and tests on macOS and Linux and the screens stay simple.
let package = Package(
    name: "BudgetKit",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "BudgetKit", targets: ["BudgetKit"])],
    targets: [
        .target(name: "BudgetKit"),
        .testTarget(name: "BudgetKitTests", dependencies: ["BudgetKit"]),
    ]
)
