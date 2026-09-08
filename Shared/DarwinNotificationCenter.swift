import Darwin
import Foundation

/// Darwin 通知：系统级跨进程通知（无需 App Group），扩展抓到新帧时唤醒主 App。
/// iOS 上 CFNotificationCenterGetDarwinNotificationCenter（macOS 专属）不可用，
/// 这里用公开的 <notify.h> API：notify_post / notify_register_dispatch。
/// notify 的回调是可捕获上下文的 block，投递后经 Task 切回 MainActor 执行 handler。
enum DarwinNotificationCenter {
    static func post(_ name: String) {
        notify_post(name)
    }

    static func addObserver(name: String, handler: @escaping @MainActor () -> Void) -> DarwinObserver {
        DarwinObserver(name: name, handler: handler)
    }
}

/// 一次观察的句柄；deinit 时 notify_cancel 注销。
final class DarwinObserver {
    private static let deliveryQueue = DispatchQueue(label: "com.yieye.darwin", qos: .userInitiated)
    private var token: Int32 = 0

    fileprivate init(name: String, handler: @escaping @MainActor () -> Void) {
        var token: Int32 = 0
        let status = notify_register_dispatch(name, &token, Self.deliveryQueue) { _ in
            Task { @MainActor in handler() }
        }
        if status == NOTIFY_STATUS_OK {
            self.token = token
        } else {
            FileLog.log("notify_register_dispatch 失败 status=\(status)")
        }
    }

    deinit {
        if token != 0 { notify_cancel(token) }
    }
}
