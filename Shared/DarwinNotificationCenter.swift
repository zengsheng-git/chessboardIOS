import CoreFoundation

/// Darwin 通知：系统级跨进程通知（无需 App Group），扩展抓到新帧时唤醒主 App。
/// CFNotificationCenter 回调不能捕获上下文，用 Unmanaged 指针把 self 传进去；
/// 回调到达后经 Task 投递回 MainActor 执行 handler。
enum DarwinNotificationCenter {
    static func post(_ name: String) {
        let center = CFNotificationCenterGetDarwinNotificationCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(name as CFString), nil, nil, true)
    }

    static func addObserver(name: String, handler: @escaping @MainActor () -> Void) -> DarwinObserver {
        DarwinObserver(name: name, handler: handler)
    }
}

/// 一次观察的句柄；deinit 时自动移除观察并释放 Unmanaged 引用。
final class DarwinObserver {
    private let name: String
    private let handler: @MainActor () -> Void
    private let opaque: UnsafeMutableRawPointer

    fileprivate init(name: String, handler: @escaping @MainActor () -> Void) {
        self.name = name
        self.handler = handler
        self.opaque = Unmanaged.passRetained(self).toOpaque()
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotificationCenter(),
            opaque,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let obs = Unmanaged<DarwinObserver>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in obs.handler() }
            },
            name as CFString,
            nil,
            .deliverSuspension
        )
    }

    deinit {
        CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotificationCenter(), opaque)
        Unmanaged.passUnretained(self).release()
    }
}
