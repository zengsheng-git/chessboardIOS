import SwiftUI
import ReplayKit

/// 系统广播启动按钮（RPSystemBroadcastPickerView）：点击后弹出系统选择器，
/// 选"弈眼"即启动抓帧扩展。iOS 不允许 App 静默开录屏，这一步必须用户点。
struct BroadcastPicker: UIViewRepresentable {
    func makeUIView(context: Context) -> RPSystemBroadcastPickerView {
        let view = RPSystemBroadcastPickerView(frame: .zero)
        view.showsMicrophoneButton = false
        view.preferredExtension = Bundle.main.bundleIdentifier?.appending(".broadcast")
        return view
    }

    func updateUIView(_ uiView: RPSystemBroadcastPickerView, context: Context) {}
}
