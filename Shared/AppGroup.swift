import Foundation

/// App Group 容器解析。
/// 免费 Apple ID 经 Sideloadly 签名时，系统会把 group ID 加上团队 ID 前缀
/// （如 `ABCDE12345.group.com.yieye.xiangqi`），entitlements 里写的标准 ID 会取不到容器。
/// 因此先试标准 ID，失败再解析 embedded.mobileprovision 里的实际授权值（Sideloadly 签名后注入）。
enum AppGroup {
    static let canonicalID = "group.com.yieye.xiangqi"

    /// 返回实际可用的 group ID 与容器目录；都取不到时为 nil（App Group 授权缺失）
    static func resolve() -> (id: String, url: URL)? {
        if let url = containerURL(for: canonicalID) {
            return (canonicalID, url)
        }
        for id in provisionedGroupIDs() {
            if let url = containerURL(for: id) {
                return (id, url)
            }
        }
        return nil
    }

    static func containerURL(for id: String) -> URL? {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            return nil
        }
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// 从签名注入的 embedded.mobileprovision 里提取实际授权的 App Group ID 列表
    static func provisionedGroupIDs() -> [String] {
        guard let profileURL = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: profileURL),
              let plist = provisioningPlist(from: data),
              let entitlements = plist["Entitlements"] as? [String: Any],
              let groups = entitlements["com.apple.security.application-groups"] as? [String] else {
            return []
        }
        return groups
    }

    /// mobileprovision 是 CMS 包，其中嵌着一段明文 XML plist；按标记截取后解析
    private static func provisioningPlist(from data: Data) -> [String: Any]? {
        guard let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8)),
              start.lowerBound < end.upperBound else { return nil }
        let xml = data.subdata(in: start.lowerBound..<end.upperBound)
        return (try? PropertyListSerialization.propertyList(from: xml, options: [], format: nil)) as? [String: Any]
    }
}
