import UIKit

/// 应用状态：解析 App Group、监听扩展发来的新帧（Darwin 通知 + 1s 兜底轮询）、维护展示数据。
/// M1 验收就看这一屏：开始录屏后"收到帧"递增、缩略图出现真实画面，整条抓帧管线即打通。
@MainActor
final class AppState: ObservableObject {
    @Published private(set) var frameCount = 0
    @Published private(set) var lastFrameDescription = "尚未收到帧"
    @Published private(set) var thumbnail: UIImage?
    @Published private(set) var containerDescription = "解析中…"
    @Published private(set) var extLogTail: [String] = []
    @Published var exportURL: URL?

    let logs = LogStore()

    private var lastSeenFrame: Int64 = -1
    private var observer: DarwinObserver?
    private var pollTimer: Timer?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    init() {
        if let group = AppGroup.resolve() {
            containerDescription = group.id
            logs.log("App Group 解析成功: \(group.id) → \(group.url.path)")
        } else {
            containerDescription = "不可用（检查签名/App Group 授权）"
            logs.log("⚠️ App Group 容器不可用，扩展帧将无法送达")
        }

        observer = DarwinNotificationCenter.addObserver(
            name: FrameContract.darwinNotification, queue: .main) { [weak self] in
            self?.pollFrame()
        }
        // 兜底轮询：Darwin 通知偶发丢失时不至于界面死等
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollFrame() }
        }
        refreshExtensionLog()
    }

    func pollFrame() {
        guard let dir = AppGroup.resolve()?.url else { return }
        guard let metaData = try? Data(contentsOf: FrameContract.metaURL(in: dir)),
              let meta = try? JSONDecoder().decode(FrameContract.Meta.self, from: metaData) else { return }
        guard meta.frameNumber > lastSeenFrame else { return }
        lastSeenFrame = meta.frameNumber

        let imageData = try? Data(contentsOf: FrameContract.jpgURL(in: dir))
        let image = imageData.flatMap(UIImage.init(data:))

        frameCount = Int(meta.frameNumber)
        let timeText = Self.timeFormatter.string(from: Date(timeIntervalSince1970: meta.timestampMs / 1000))
        lastFrameDescription = "第 \(meta.frameNumber) 帧 @ \(timeText)（\(meta.width)×\(meta.height)）"
        if let image { thumbnail = image }
        logs.log("收到帧 \(meta.frameNumber) \(meta.width)×\(meta.height)")
        refreshExtensionLog()
    }

    func refreshExtensionLog() {
        extLogTail = FileLog.tail(of: "ext")
    }

    /// 生成日志导出文件（供 ShareLink 分享）
    func makeExportFile() {
        exportURL = logs.writeExportFile()
        if exportURL == nil { logs.log("日志导出失败") }
    }
}
