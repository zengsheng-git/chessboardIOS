import Foundation

/// Darwin 通知：系统级跨进程通知（无需 App Group），扩展抓到新帧时唤醒主 App。
/// iOS 的 Swift 模块未映射 <notify.h> 符号（CFNotificationCenter 的 Darwin 中心又是
/// macOS 专属），经 NotifyBridge.h（C 桥）调用公开的 libsystem_notify API。
/// notify 的回调是可捕获上下文的 block，投递后经 Task 切回 MainActor 执行 handler。
enum DarwinNotificationCenter {
    static func post(_ name: String) {
        YiEyeNotifyPost(name)
    }

    static func addObserver(name: String, handler: @escaping @MainActor () -> Void) -> DarwinObserver {
        DarwinObserver(name: name, handler: handler)
    }
}

/// 一次观察的句柄；deinit 时注销观察。
final class DarwinObserver {
    private static let deliveryQueue = DispatchQueue(label: "com.yieye.darwin", qos: .userInitiated)
    private var token: Int32 = 0

    fileprivate init(name: String, handler: @escaping @MainActor () -> Void) {
        var token: Int32 = 0
        let status = YiEyeNotifyRegisterDispatch(name, &token, Self.deliveryQueue) { _ in
            Task { @MainActor in handler() }
        }
        if status == 0 {
            self.token = token
        } else {
            FileLog.log("notify_register_dispatch 失败 status=\(status)")
        }
    }

    deinit {
        if token != 0 { YiEyeNotifyCancel(token) }
    }
}
