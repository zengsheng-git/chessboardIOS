import ReplayKit
import CoreVideo

/// 抓帧扩展（M1 管线，M2 spike 的核心）：只做最轻量的帧搬运——
/// 降采样(≤1080) → JPEG → 32×32 灰度 aHash 去重（对齐 Android 版语义，画面没变不搬运）
/// → 写 App Group 容器 → Darwin 通知主 App。
/// 扩展进程内存受限，YOLO 推理与引擎分析都在主 App 侧做。
class SampleHandler: RPBroadcastSampleHandler {
    private let frameInterval: CFTimeInterval = 0.3   // 对齐 Android 版 LOOP_INTERVAL_MS
    private let maxDimension: CGFloat = 1080
    private let jpegQuality: Double = 0.6
    private let pHashThreshold = 2                    // 对齐 Android 版 PHASH_THRESHOLD

    private var frameNumber: Int64 = 0
    private var lastAcceptedTime: CFTimeInterval = 0
    private var lastHash: [UInt64]?
    private var groupDir: URL?

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        frameNumber = 0
        lastAcceptedTime = 0
        lastHash = nil
        groupDir = nil
        FileLog.log("broadcastStarted")
        guard AppGroup.resolve() != nil else {
            finishBroadcastWithError(NSError(
                domain: "com.yieye.xiangqi", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "App Group 容器不可用：请用同一 Apple ID 签名安装主 App 与扩展"]))
        }
    }

    override func broadcastFinished() {
        FileLog.log("broadcastFinished, frames=\(frameNumber)")
    }

    // 方法名以 SDK 的 Swift 导入名为准（processSampleBuffer(_:with:)）
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        guard sampleBufferType == .video else { return }
        autoreleasepool {
            let pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
            guard pts.isFinite, pts - lastAcceptedTime >= frameInterval else { return }
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            lastAcceptedTime = pts
            handleFrame(pixelBuffer)
        }
    }

    private func handleFrame(_ pixelBuffer: CVPixelBuffer) {
        if groupDir == nil { groupDir = AppGroup.resolve()?.url }
        guard let dir = groupDir else {
            FileLog.log("App Group 容器缺失，终止广播")
            finishBroadcastWithError(NSError(
                domain: "com.yieye.xiangqi", code: 1,
                userInfo: [NSLocalizedDescriptionKey: "App Group 容器不可用"]))
            return
        }

        guard let scaled = ImageTools.scaledCGImage(from: pixelBuffer, maxDimension: maxDimension) else { return }

        // pHash 去重：画面没变就不搬运（语义对齐 Android 版 captureFrame 的 pHash 分支）
        if let hash = ImageTools.averageHash(of: scaled) {
            if let prev = lastHash, ImageTools.hammingDistance(hash, prev) <= pHashThreshold {
                return
            }
            lastHash = hash
        }

        guard let jpeg = ImageTools.jpegData(from: scaled, quality: jpegQuality) else {
            FileLog.log("JPEG 编码失败")
            return
        }

        let meta = FrameContract.Meta(
            frameNumber: frameNumber + 1,
            timestampMs: Date().timeIntervalSince1970 * 1000,
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer))

        do {
            try jpeg.write(to: FrameContract.jpgURL(in: dir), options: .atomic)
            try JSONEncoder().encode(meta).write(to: FrameContract.metaURL(in: dir), options: .atomic)
        } catch {
            FileLog.log("写帧失败: \(error.localizedDescription)")
            return
        }
        frameNumber = meta.frameNumber
        DarwinNotificationCenter.post(FrameContract.darwinNotification)
    }
}
