# 弈眼 iOS (YiEye iOS)

中国象棋实时分析助手「弈眼」的 iOS 版：截取屏幕上棋类 App 的棋盘画面 → YOLO 识别棋子 → Pikafish 引擎 / chessdb.cn 云库计算 → 悬浮提示推荐走法。与 Android 版（[chessboardAndroid](https://github.com/zengsheng-git/chessboardAndroid)）同源同逻辑，当前处于 **M1（工程骨架与云构建链路）** 阶段。

## 无 Mac 构建链路

本仓库用 GitHub Actions 的 macOS runner 编译：push 后自动产出未签名 IPA（Artifacts 下载），Windows 端用 Sideloadly + 免费 Apple ID 签名安装到 iPhone。完整步骤见 **[docs/ios-setup-guide.md](docs/ios-setup-guide.md)**，整体技术方案见 **[docs/ios-port-plan.md](docs/ios-port-plan.md)**。

## 结构

```
project.yml            XcodeGen 工程描述（CI 上生成 YiEye.xcodeproj，工程文件不入库）
YiEye/                 主 App（SwiftUI）：状态机/识别/引擎接入的宿主 + M1 验收界面
BroadcastExtension/    ReplayKit 抓帧扩展：降采样 → pHash 去重 → App Group 容器 → Darwin 通知
Shared/                两进程共享代码：App Group 解析、帧契约、跨进程通知、文件日志
CoreLogic/             纯逻辑层 Swift Package（FEN/中文记谱/棋盘对比/状态机，带单测）
scripts/               资产与辅助脚本
docs/                  技术方案与安装指南
```

## 状态（里程碑）

- [x] M1 工程骨架 + CI 出 IPA（当前）
- [ ] M2 go/no-go spike：扩展抓帧 → 主 App 画中画（PiP）悬浮显示 + 后台保活
- [ ] M3 CoreLogic 逻辑移植（对齐 Android 版）+ 单测
- [ ] M4 Pikafish iOS 编译与桥接
- [ ] M5 识别管线（ONNX Runtime + middle.onnx）+ 端到端出招
- [ ] M6 PiP 提示完整化 + 云库
- [ ] M7 稳定性与打磨

## 许可

GNU GPLv3（见 [LICENSE](LICENSE)），因集成 Pikafish（GPLv3）源码与 GPLv3 识别模型。第三方组件说明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 免责声明

本项目仅供学习交流与个人技术研究使用，不得用于任何形式的商业作弊、破坏公平竞技环境等用途，因使用本项目产生的一切后果由使用者自行承担。
