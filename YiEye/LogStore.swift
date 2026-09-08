import Foundation

/// 主 App 运行日志：界面展示 + 导出文件（无 Mac 调试的生命线）。
@MainActor
final class LogStore: ObservableObject {
    @Published private(set) var lines: [String] = []

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private let capacity = 500

    func log(_ message: String) {
        let line = "[\(Self.formatter.string(from: Date()))] \(message)"
        lines.append(line)
        if lines.count > capacity { lines.removeFirst(lines.count - capacity) }
        FileLog.log(message)
    }

    var exportText: String { lines.joined(separator: "\n") }

    func clear() { lines.removeAll() }

    func writeExportFile() -> URL? {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("yieye-ios-logs-\(Int(Date().timeIntervalSince1970)).txt")
        do {
            try exportText.data(using: .utf8)?.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
