// swift-tools-version:5.9
// 弈眼纯逻辑层（M3 起从 Android 版逐项移植：FEN/中文记谱/棋盘对比/isValidFen/UCI/云库/状态机）。
// 纯 Foundation，可在 macOS / Linux 上 swift test（CI 免费额度跑单测的主力）。
import PackageDescription

let package = Package(
    name: "CoreLogic",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "CoreLogic", targets: ["CoreLogic"])
    ],
    targets: [
        .target(name: "CoreLogic"),
        .testTarget(name: "CoreLogicTests", dependencies: ["CoreLogic"])
    ]
)
