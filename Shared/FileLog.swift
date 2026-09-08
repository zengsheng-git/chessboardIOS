import Foundation

/// 文件日志（App / 扩展各一份）：没有 Mac 和 Xcode console，这是排障主通道。
/// 写入 App Group 容器（app.log / ext.log），超 256KB 轮换为 .old.log；
/// 主 App 界面提供"导出日志"（app.log 全量随富文本视图分享）与扩展日志尾部查看。
enum FileLog {
    private static let queue = DispatchQueue(label: "com.yieye.filelog", qos: .utility)

    /// 当前进程身份：扩展进程的 bundle 路径以 .appex 结尾
    private static let processName: String = {
        Bundle.main.bundlePath.hasSuffix(".appex") ? "ext" : "app"
    }()

    static func log(_ message: String) {
        let line = "[\(timestamp())] [\(processName)] \(message)\n"
        queue.async {
            guard let dir = AppGroup.resolve()?.url else { return }
            let url = dir.appendingPathComponent("\(processName).log")
            let fm = FileManager.default
            if let attrs = try? fm.attributesOfItem(atPath: url.path),
               let size = attrs[.size] as? UInt64, size > 256 * 1024 {
                let old = dir.appendingPathComponent("\(processName).old.log")
                try? fm.removeItem(at: old)
                try? fm.moveItem(at: url, to: old)
            }
            if let handle = FileHandle(forWritingAtPath: url.path) {
                defer { try? handle.close() }
                handle.seekToEndOfFile()
                if let data = line.data(using: .utf8) { handle.write(data) }
            } else {
                try? line.data(using: .utf8)?.write(to: url, options: .atomic)
            }
        }
    }

    /// 读取指定日志的尾部若干行（主 App 展示扩展日志用）
    static func tail(of name: String, maxLines: Int = 40) -> [String] {
        guard let dir = AppGroup.resolve()?.url,
              let text = try? String(contentsOf: dir.appendingPathComponent("\(name).log"), encoding: .utf8) else {
            return []
        }
        return text.split(separator: "\n").suffix(maxLines).map(String.init)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
}
