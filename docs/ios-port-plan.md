# 弈眼 iOS 版技术方案

> 状态：方案设计稿（M0）。本文档回答两个问题：**没有 Mac 能不能做 iOS 版**（能，全链路方案见 §2）、**怎么做**（架构与里程碑见 §3–§7）。
> 基准：Android 版弈眼 0.0.35（本仓库），桌面端 chessboard 原型的对齐关系继续沿用。

---

## 1. 结论摘要

- **技术上完全可行**。Pikafish C++ 源码、middle.onnx 模型、全部识别/状态机逻辑都可以复用；需要重写的只有 UI、截屏接入和"悬浮窗"显示层。
- **没有 Mac 也能完成 编码 → 编译 → 真机安装 → 迭代调试** 的完整闭环：
  编码用普通编辑器（Swift 是文本）；编译用 **GitHub Actions 的 macOS 云构建**（公开仓库免费）；安装用 **Windows 端 Sideloadly / SideStore 自签**；调试用 App 内日志导出代替 Xcode console。
- **最大技术风险只有一个**：iPhone 上没有悬浮窗，只能用画中画（PiP）方案承载提示窗口。这是 go/no-go 级别的风险，里程碑 M2 第一时间真机验证；iPad 有免 hack 的正道（Slide Over）。
- **不做上架 App Store**：这类"旁观分析辅助 + PiP 擦边"的 App 过审概率低，目标是自用 sideload（与 Android 版的免责声明一致）。

---

## 2. 无 Mac 的构建与安装链路（"怎么编译"）

### 2.1 各环节工具链

| 环节 | Windows 现实方案 | 说明 |
|---|---|---|
| 写代码 | 任意编辑器（本仓库工作流） | Swift / Objective-C++ / YAML 都是文本；`.xcodeproj` 不手写，用 **XcodeGen** 从 `project.yml` 生成（CI 上生成，本地无需安装） |
| 编译 | **GitHub Actions** `macos-14/15` runner | 公开仓库**免费不限时**；私有仓库免费额度折算约 200 分钟 macOS/月（构建一次约 10–20 分钟，自用足够）。备选 Codemagic（免费 500 min/月）、按小时租云 Mac（MacStadium / 阿里云 mac 机型） |
| 产物 | unsigned / development 签名 `.ipa` | CI artifact 下载回来 |
| 签名安装 | **Sideloadly**（Windows 原生）或 **AltServer for Windows**；**SideStore**（装到设备后可设备端自动续签） | 用自己的免费 Apple ID 自签：7 天有效期、同一设备最多 3 个自签应用；App Group 能力可用（AltStore/SideStore 自身就依赖 App Group 续签）。付费开发者账号（$99/年）有效期变 1 年 |
| 设备配对 | Windows 装 iTunes（或 iCloud 驱动）+ USB | Sideloadly/SideStore 依赖 |
| 看日志 | **App 内日志查看器**（移植时顺带做）：环形缓冲 + 导出分享 | 没有 Xcode console，这是调试的生命线；崩溃日志可在设备 设置→隐私→分析与改进 里导出 |

### 2.2 推荐工作流

```
Windows 写码/改码 → git push → GitHub Actions 构建 .ipa
  → 下载 artifact → Sideloadly 自签安装到 iPhone（USB）
  → 真机运行 → App 内导出日志 → 回到 Windows 改码
```

- 日常迭代每次约 20–30 分钟（构建 + 安装），比有 Mac 慢，但完全可迭代。
- 纯逻辑单元测试不走 iOS：CoreLogic 做成 Swift Package，在 GitHub Actions 的 **Linux runner**（免费、更快）上 `swift test`。
- 第一次搭流水线时把"构建 → 安装 → 拉日志"写成脚本/文档，之后就是机械操作。

---

## 3. 总体架构

### 3.1 iPhone 路线（PiP 方案）

```
[用户在控制中心点"屏幕录制"选弈眼，或先在弈眼 App 内点启动按钮]
        │  ReplayKit Broadcast Upload Extension（独立进程）
        │  抓帧 → 降采样 JPEG → 写 App Group 容器 + Darwin 通知（扩展端 pHash 节流）
        ▼
[主 App]（PiP 会话保活，后台不被挂起）
   读帧 → smartCrop → YOLO 识别（onnxruntime + middle.onnx）→ FEN
   → 状态机（帧守卫/丢王修复/预期棋盘，逻辑照抄 Android 版）
   → 云库 chessdb.cn → 失败落 Pikafish（进程内 C++，ObjC++ 桥）
   → 把提示内容用 Core Graphics 画成位图 → 塞进 PiP 窗口显示
```

### 3.2 Android → iOS 模块映射

| Android（本仓库） | iOS 对应 | 移植方式 |
|---|---|---|
| `AnalysisService.java` 截屏循环 | `CaptureExtension`（ReplayKit）+ `AnalysisEngine.swift`（主 App） | 架构重写，**状态机逻辑照抄** |
| `MediaProjection` + `ImageReader` | Broadcast Upload Extension + `CMSampleBuffer` | 重写 |
| `ChessBoardParser`（smartCrop/网格） | `BoardRecognizer.swift` | 逻辑照抄翻译 |
| `YoloV5Detector` / `YoloV11Detector` | onnxruntime-objc 同款后处理 | 逻辑照抄翻译 |
| `Utils.java`（FEN/中文记谱/diff） | CoreLogic Swift Package | 纯函数，照抄 + 单测 |
| `EngineHelper`（UCI 协议/searchSync） | `PikafishEngine.swift` + ObjC++ 桥 | 协议逻辑照抄 |
| `pikafish_jni.cpp`（JNI 桥） | `PikafishBridge.mm`（ObjC++，复用源码里已有的输出回调钩子） | 重写桥 |
| `ChessDB.java`（云库） | `ChessDBClient.swift` | 照抄，注意 ATS（§4.6） |
| `FloatWindowManager` + `BoardView` | **PiP 窗口渲染器**（iPhone）/ 普通视图（iPad Slide Over） | 重写，交互靠系统 PiP 手势 |
| `MainActivity` | SwiftUI 主界面（启动/深度/日志/设置） | 重写 |
| 前台服务保活 | PiP 会话保活（§4.2） | 重写 |

### 3.3 进程与内存模型差异（设计约束的来源）

| | Android | iOS |
|---|---|---|
| 截屏进程 | 主 App 服务内 | **独立扩展进程，内存上限低**（历史约 50MB，新系统放宽但有限）→ 扩展只做抓帧+降采样+pHash，不做 YOLO/引擎 |
| 主 App 后台存活 | 前台服务类型即可 | 无前台服务；靠 **PiP 会话**保活（§4.2） |
| 叠加窗口 | `SYSTEM_ALERT_WINDOW` | **不存在**；PiP 或 iPad Slide Over |
| 启动截屏 | App 内授权后全自动 | 每次会话需用户手动启动（控制中心或 App 内 `RPSystemBroadcastPickerView` 按钮），**无法静默自动开** |

---

## 4. 关键设计

### 4.1 截屏：Broadcast Upload Extension

- Target：`BroadcastExtension`（Upload 类型），Bundle ID `com.yieye.xiangqi.broadcast`，与主 App 共享 App Group `group.com.yieye.xiangqi`。
- 帧处理（扩展内，控制 CPU/内存）：
  1. `CMSampleBuffer` → `CVPixelBuffer` → 缩放到宽 720–1080 → JPEG（质量 0.6，约 0.3–1MB/帧）。
  2. 扩展内算 pHash（灰度 32×32，成本可忽略），与上一帧汉明距离 ≤2 则丢弃——把 Android 版的去重前移到扩展，省 IPC。
  3. 通过节流（≥300ms）后写 App Group 容器：`frame.jpg` + `meta.json`（时间戳、屏幕方向、原始宽高），发 Darwin 通知 `com.yieye.frame` 唤醒主 App 处理。
- 主 App 收到通知读文件处理；分析节拍沿用 Android 的 300ms 循环语义（识别+引擎在主 App，单线程串行，竞态模型不变）。
- **备选优化（非首期）**：把 YOLO 转成 Core ML 在扩展内直接识别输出 FEN JSON，把 IPC 压到最小；内存是否允许需真机验证，首期不做。

### 4.2 悬浮显示：PiP（iPhone 的唯一现实路径）

- 实现：`AVSampleBufferDisplayLayer` + `AVPictureInPictureController`（自定义 `AVPictureInPictureSampleBufferPlaybackDelegate`）。提示 UI 用 Core Graphics 渲染成位图（富文本 + 棋盘高亮，对齐 Android 的 Spannable 配色和 BoardView），作为视频帧 enqueue 进 PiP 窗口。
- **保活原理**：PiP 会话活跃期间主 App 进程不被挂起——正好满足"分析循环要一直跑"。兜底再挂一路静音音频会话（background mode: audio）。
- 交互：拖动/收起/关闭都是系统 PiP 手势，不需要自己实现；窗口比例按棋盘 ~1:1.12 设置。
- 内容变化时才重绘（≤10fps），功耗可控。
- 风险：iOS 各版本对"非视频内容 PiP"的容忍度不同（系统可能回收窗口）——**M2 spike 第一时间验证**。若 PiP 不可行：iPhone 退化为"App 内显示"（体验大打折扣，用户需来回切换），或 iPad 路线。
- iPad：**Slide Over / 台前调度**是正道——弈眼小窗与棋类 App 并排，普通视图显示，无需任何 hack，审核也干净。若有 iPad，优先用 iPad 路线联调整条识别/引擎链路。

### 4.3 引擎：Pikafish iOS

- 源码（2.1MB，Pikafish 2026-01-02，含 zstd/NNUE）直接加入 Xcode target（或 CMake 生成静态库）；编译宏与 Android 版 CMakeLists 相同：`IS_64BIT USE_NNUE USE_NEON USE_POPCNT NDEBUG`，`-O3 -flto`，arm64。
- Android 版给 Pikafish 源码加过输出回调钩子（`set_jni_callback`），iOS 桥复用同一钩子：`PikafishBridge.mm` 持有回调 → 转发给 Swift 的 UCI 行解析器。
- 引擎初始化参数照抄桌面端/Android 端：`Hash 64 / Threads 4 / MultiPV 3 / Sixty Move Rule false`；`pikafish.nnue`（51MB）从 Bundle 拷到 Documents，`EvalFile` 指向该路径（`noCompress` 等价于 Xcode 的 "bundle 不压缩/拷贝资源" 设置）。
- 主 App 内存充裕：NNUE（~100MB 加载后）+ ONNX 会话（28MB 模型，~100MB）+ 帧缓冲，合计 300MB 级，远低于 iOS 对主 App 的限制。
- `isValidFen`（九宫/士象兵位置 + 兵种上限）**必须最先移植**——Android 版的经验：非法局面会让 Pikafish 原生层崩溃。

### 4.4 识别：ONNX Runtime

- 依赖：`onnxruntime-objc`（SwiftPM），`middle.onnx`（28MB）原样复用，无需转换即可上真机；后处理（objConf×类别概率、王类 0.2 放宽、每类 CLASS_LIMITS、NMS）从 `YoloV5Detector.java` 照抄。
- smartCrop + 裁剪缓存 + "连续 3 次识别失败清缓存"逻辑照抄（`ChessBoardParser.java`）。
- 可选后续优化：在 CI（macOS runner）上用 coremltools 转成 Core ML 走 Neural Engine，更快更省电；首期不做，保持与 Android 端可 A/B 对比。

### 4.5 纯逻辑移植清单（CoreLogic Swift Package，带单测）

照抄 Android 版行为，逐项配单测（这是整个项目里最有把握、可在 Linux CI 上反复跑的部分）：

- FEN：`fenToBoard` / `boardToFen`（红下基准 + 镜像）/ `applyMoveToFen`（预期棋盘）/ `mirrorFen*`
- 中文记谱 `fenToChina`（含前/中/后、进退平、SBC 数字）
- `compareBoard`（diffCount/redDiff/blackDiff/movedChess）与 `boardDiff` 分类（ONE/MOVE/UNKNOWN）
- `isValidFen` 位置规则
- 云库 `ChessDBClient`（querypv/queryall 协议 + 状态语义 + 熔断计数）
- UCI 解析（info/multipv/bestmove、mate→±30000 编码、SearchCollector 次优过滤 altScoreGap=300）
- 状态机（INITIAL/GENERIC/INVALID、pHash 回滚、噪声帧守卫、丢王修复三层、王位记忆、预期棋盘命中）——以移植测试用例优先，行为对齐 Android 版注释里记录的每个案例

### 4.6 网络：ATS

chessdb.cn 是 **http**，iOS 默认拦截明文 HTTP。`Info.plist` 加 `NSAppTransportSecurity` 按域例外（`NSExceptionDomains: www.chessdb.cn`），或先探测 `https://www.chessdb.cn` 是否可用再决定。UA/Referer 头照抄 Android 版。

### 4.7 其他系统行为

- 每次分析会话：用户先在弈眼内点"启动"（弹 PiP 窗口、保活生效）→ 再开控制中心录屏选弈眼（扩展跑起来）。两步顺序写入 App 内引导页。
- 屏幕方向/尺寸变化：扩展的 `meta.json` 带原始宽高，主 App 每帧按需重算裁剪缓存。
- 耗电对标 Android：300ms 节拍 + pHash 去重 + 引擎 movetime 5s 的组合不变。

---

## 5. 工程结构

```
chessboardIOS/                  # 独立仓库 https://github.com/zengsheng-git/chessboardIOS（本地 C:\w\chessboardIOS）
  project.yml                  # XcodeGen 描述（App + BroadcastExtension 两个 target、App Group 能力）
  YiEye/                       # 主 App（SwiftUI）
    Analysis/                  # AnalysisEngine（状态机循环）、BoardRecognizer、PikafishEngine 封装（M3/M4 落位）
    Overlay/                   # PiP 渲染器（提示富文本 + 棋盘高亮位图，M2/M6 落位）
    Support/                   # 日志环形缓冲/导出、设置
  BroadcastExtension/          # 抓帧扩展：降采样、pHash、App Group 写入
  Shared/                      # 两进程共享：App Group 解析、帧契约、Darwin 通知、文件日志
  CoreLogic/                   # Swift Package（§4.5，Linux CI 可测）
    Sources/Tests/
  EngineBridge/                # PikafishBridge.mm ObjC++ 桥（M4 落位）
  scripts/
    fetch-assets.sh            # CI 上从安卓仓库（二次检出）拷贝模型与 NNUE（不双份入库）
.github/workflows/ios-build.yml # macOS 构建 .ipa + Linux 跑 CoreLogic 测试
```

资产策略：`middle.onnx`、`pikafish.nnue` 不复制进本仓库，CI 构建时二次检出安卓仓库 `chessboardAndroid` 后由 `scripts/fetch-assets.sh` 拷贝，单一大文件只存一份。

---

## 6. CI 流水线（GitHub Actions）

- `ios-build.yml`（macos-14）：
  1. checkout → 运行 `scripts/fetch-assets.sh`
  2. `brew install xcodegen && xcodegen generate`
  3. `xcodebuild archive -scheme YiEye -configuration Release` → `xcodebuild -exportArchive`（或直接 `xcodebuild build` 取 .app 打包成未签名 .ipa）
  4. 上传 artifact
- `corelogic-tests.yml`（ubuntu，免费额度充裕）：`swift test`，PR 必跑。
- 触发：push 到 `main` 或手动；缓存 SPM/CocoaPods 依赖加速二次构建。

---

## 7. 里程碑（风险前置）

| 阶段 | 内容 | 验证方式 | 依赖 |
|---|---|---|---|
| M0 | 本方案文档 | — | — |
| M1 | 工程骨架 + CI：XcodeGen 工程、Broadcast 空扩展、流水线出 .ipa | CI 绿、Sideloadly 装上真机 | 无 Mac 可行 |
| **M2** | **go/no-go spike**：扩展抓帧 → App Group → 主 App PiP 显示占位画面，验证悬浮窗成立 + 后台不被杀 | 真机 | 需真机（无 Mac 链路） |
| M3 | CoreLogic 移植 + 单测（FEN/记谱/diff/isValidFen/UCI/云库/状态机） | Linux CI 全绿 | 无 |
| M4 | Pikafish iOS 编译 + ObjC++ 桥 + NNUE 加载 | CI 编译 + 真机 smoke（固定 FEN 出 bestmove） | 无 Mac 可行（CI） |
| M5 | 识别管线（onnxruntime + smartCrop）+ 状态机整合，端到端出招 | 真机看日志/悬浮窗 | M2–M4 |
| M6 | PiP 内容完整化（富文本提示 + 棋盘高亮镜像）+ 云库 + 设置/引导页 | 真机 | M5 |
| M7 | 稳定性：看门狗、日志导出完善、耗电/发热评估、免费证书 7 天续签流程固化 | 长时间对局实测 | M6 |

M2 是分水岭：PiP 若被系统回收/无法保活，iPhone 路线降级为"App 内显示"或转 iPad 主力，后续里程碑不受影响（识别/引擎/逻辑完全复用）。

---

## 8. 风险清单

| 风险 | 影响 | 对策 |
|---|---|---|
| PiP 显示非视频内容被系统回收（版本相关） | iPhone 路线 no-go | M2 最早验证；挂静音音轨提高存活率；iPad Slide Over 兜底 |
| Broadcast 扩展内存超限被杀 | 录屏中断 | 扩展只做抓帧+降采样+pHash；帧率/尺寸保守（720p JPEG）；主 App 承担重活 |
| 免费 Apple ID 限制（7 天过期 / 3 应用 / 设备绑定） | 反复重签麻烦 | SideStore 设备端自动续签；重度自用建议 $99 开发者账号 |
| ATS 拦截 http 云库 | 云库不可用 | 按域例外或探测 https |
| 部分棋类 App 防录屏（受保护内容录出来是黑屏） | 识别不到 | 概率低（游戏类极少防录屏）；遇到则该 App 无解，如实标注 |
| 无 Xcode console 调试效率低 | 排障慢 | App 内日志查看器 + 导出；崩溃日志设备端导出；CoreLogic 单测前置减少真机调试面 |
| XcodeGen/CI 首次调通成本 | M1 变慢 | 一次性成本；先用最小空工程把流水线跑绿 |

---

## 9. 已确认决策

1. **iPhone PiP 路线**：接受（自用 sideload，不涉及上架），M2 真机验证。
2. **是否有 iPad**：待确认（有则 iPad Slide Over 路线优先联调）。
3. **付费开发者账号（$99/年）**：暂不，先用免费 Apple ID + SideStore 续签。
4. **代码落位（已定）**：独立仓库 `https://github.com/zengsheng-git/chessboardIOS`（Public，本地 `C:\w\chessboardIOS`），不在安卓仓库内；GPLv3 与第三方声明随仓库携带，模型/NNUE 资产仍以安卓仓库为单一来源（CI 二次检出）。
