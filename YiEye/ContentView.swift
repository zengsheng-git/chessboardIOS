import SwiftUI

/// M1 主界面：验收目标 = 开始录屏后"收到帧"递增、缩略图出现投屏画面。
/// 识别/引擎/M2 PiP 均未接入——这是纯链路验证版。
struct ContentView: View {
    @StateObject private var app = AppState()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        BroadcastPicker()
                            .frame(height: 44)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("开始屏幕录制")
                                .font(.body)
                            Text("点击左侧按钮，选择“弈眼”，然后去打开棋类 App")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("第 1 步 · 启动抓帧")
                }

                Section {
                    LabeledContent("收到帧", value: "\(app.frameCount)")
                    LabeledContent("最近帧", value: app.lastFrameDescription)
                    LabeledContent("App Group", value: app.containerDescription)
                    if let thumb = app.thumbnail {
                        Image(uiImage: thumb)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 220)
                            .cornerRadius(8)
                    }
                } header: {
                    Text("第 2 步 · 确认画面送达")
                } footer: {
                    Text("录制中若帧数持续增长且缩略图与手机当前画面一致，说明抓帧管线正常（M1 验收通过）。")
                }

                Section {
                    Button("刷新") { app.refreshExtensionLog() }
                    if app.extLogTail.isEmpty {
                        Text("（暂无扩展日志）").font(.footnote).foregroundStyle(.secondary)
                    } else {
                        LogLines(lines: Array(app.extLogTail.suffix(40)))
                    }
                } header: {
                    Text("抓帧扩展日志（尾部 40 行）")
                }

                Section {
                    Button("生成导出文件") { app.makeExportFile() }
                    if let url = app.exportURL {
                        ShareLink(item: url)
                    }
                    Button("清空界面日志") { app.logs.clear() }
                    LogLines(lines: Array(app.logs.lines.suffix(60)))
                } header: {
                    Text("运行日志")
                }
            }
            .navigationTitle("弈眼 iOS · M1")
        }
    }
}

/// 等宽小字号的日志行列表（新行在前）
struct LogLines: View {
    let lines: [String]

    var body: some View {
        ForEach(lines.indices.reversed(), id: \.self) { index in
            Text(lines[index])
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}
