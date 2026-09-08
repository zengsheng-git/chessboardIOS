import Foundation

/// 主 App 与 Broadcast 扩展之间的帧交换契约。
/// 扩展端：写 frame.jpg（原子写）→ 写 frame.json → post Darwin 通知；
/// 主 App 端：收到通知（或 1s 兜底轮询）后读取两者，按 frameNumber 去重。
/// 只保留"最新一帧"，历史帧直接覆盖——分析侧自带节奏（对齐 Android 版 300ms 节拍）。
enum FrameContract {
    static let darwinNotification = "com.yieye.xiangqi.newFrame"
    static let jpgName = "frame.jpg"
    static let metaName = "frame.json"

    struct Meta: Codable {
        var frameNumber: Int64
        var timestampMs: Double
        var width: Int
        var height: Int
    }

    static func jpgURL(in dir: URL) -> URL { dir.appendingPathComponent(jpgName) }
    static func metaURL(in dir: URL) -> URL { dir.appendingPathComponent(metaName) }
}
