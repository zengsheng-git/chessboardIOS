# 弈眼 iOS 版：从零安装指南（不需要 Mac）

> 本指南覆盖 M1 里程碑的完整链路：**代码上云 → 云端 Mac 编译 → Windows 签名 → 装进 iPhone → 验收**。
> 全程只用到：这台 Windows 电脑、一根数据线、你的 Apple ID、一个 GitHub 账号。总费用：0 元。
>
> 背景与整体方案见 [ios-port-plan.md](ios-port-plan.md)。

---

## 0. 前置清单

| 需要的东西 | 说明 |
|---|---|
| iPhone 一台 | iOS 16 及以上 |
| 数据线 | USB 连电脑用（首次需要在手机上点"信任"） |
| Apple ID | 就是你登录 iPhone 的那个账号，免费即可 |
| GitHub 账号 | 没有的话到 [github.com/signup](https://github.com/signup) 注册（免费） |
| Windows 电脑 | 就是当前这台，需要能装软件 |

---

## 1. 把代码推到 GitHub

> **本仓库已就绪**：`https://github.com/zengsheng-git/chessboardIOS` 是 **Public 公开仓库**（macOS 云构建免费不限时长，无额度顾虑），本地代码在 `C:\w\chessboardIOS`。代码推送通常由 ZCode 代办；如需自己推：

```bash
cd C:\w\chessboardIOS
git add -A
git commit -m "..."
git push -u origin main
```

> 推送时如要求登录，按提示浏览器授权 GitHub 即可。

### 1.1 确认云端构建启动

1. 打开你仓库的网页 → 顶部 **Actions** 标签页。
2. 应能看到 **ios-build** 工作流正在运行（黄色圆点 = 进行中）。
3. 首次构建约 10~20 分钟。成功后变绿色 ✓。

> 如果列表里没有 ios-build：检查推送是否成功；Actions 页面若有黄色横幅提示启用，点 **I understand my workflows, go ahead and enable them**。

---

## 2. 下载编译好的 IPA

1. 进入该次构建的详情页（点那条绿色 ✓ 记录），滚到页面最底部 **Artifacts** 区域。
2. 点击 **YiEye-unsigned-ipa** 下载，得到压缩包，解压出 **`YiEye-unsigned.ipa`**。
3. 记住这个文件的位置，比如放到 `C:\Users\你的用户名\Downloads\`。

---

## 3. Windows 端准备（一次性）

### 3.1 安装 iTunes（目的：让 Windows 认出 iPhone，装驱动）

- 用 **Microsoft Store** 搜 "iTunes" 安装即可。
- 如果后面 Sideloadly 始终提示找不到设备，改装 **Apple 官网直装版**：到 [apple.com.cn/itunes](https://www.apple.com.cn/itunes/) 页面下载 Windows 版安装，装完重启电脑。

### 3.2 安装 Sideloadly

- 到官网 [sideloadly.io](https://sideloadly.io) 下载 Windows 版，安装。

### 3.3 创建 Apple ID 的"App 专用密码"（开了双重认证的账号必需，一般都开了）

1. 浏览器打开 [appleid.apple.com](https://appleid.apple.com) 并登录。
2. **登录与安全** → **App 专用密码** → 点 **+** 生成一个，名字随意（比如 `sideloadly`）。
3. 复制生成的密码（格式如 `abcd-efgh-ijkl-mnop`），后面要用。

---

## 4. 签名并安装到 iPhone

1. iPhone 用数据线连电脑，手机上弹出"要信任此电脑吗"→ 点**信任**并输锁屏密码。
2. 打开 Sideloadly：
   - **Apple account** 填你的 Apple ID 邮箱；
   - **Password** 填上一步的 **App 专用密码**（不是 Apple ID 登录密码）；
   - 把 `YiEye-unsigned.ipa` 拖进窗口中间；
   - 点 **Start**。第一次会向 Apple 申请开发证书，约 1~2 分钟，出现 **Done / Success** 即完成。
3. 手机上：**设置 → 通用 → VPN 与设备管理** → 找到你的 Apple ID 邮箱条目 → 点**信任**。
4. 桌面出现"弈眼"图标，可以打开了。

> 免费账号的限制（重要）：
> - 签名 **7 天过期**，过期后 App 打不开，重做第 4 步即可（数据不丢）；
> - 同一设备最多 **3 个**自签应用，装不下时先删掉不用的。

---

## 5. M1 验收（拿到手机上检查这几条）

| # | 操作 | 预期 |
|---|---|---|
| 1 | 打开"弈眼" | 看到"弈眼 iOS · M1"界面，App Group 一栏显示 `group.com.yieye.xiangqi`（或带前缀的 ID）而不是"不可用" |
| 2 | 点"开始屏幕录制"按钮 | 弹出系统选择器，列表里有"弈眼"；选择并点"开始直播" |
| 3 | 状态栏出现红框后，随便滑动手机屏幕 | 回到弈眼：**收到帧持续增加**，缩略图显示的就是手机当前画面 |
| 4 | 点"生成导出文件"→ 分享 | 能把日志文件通过微信/文件等方式发出来（排障通道验收） |

四条都过 = M1 完成，M2（悬浮窗 PiP + 保活 spike）的输入已就绪。有问题就把导出的日志文件发回给 ZCode 分析。

---

## 6. 以后更新版本怎么办

1. 代码改完推送到 GitHub → Actions 自动出新的 IPA。
2. **直接把新 IPA 用 Sideloadly 再装一遍**（同一步骤）。同一 Apple ID 签名可以覆盖升级，数据保留。
3. 7 天过期问题想一劳永逸：装 [SideStore](https://sidestore.io)（把签名续期搬到手机端自动做，配置稍繁琐，M1 阶段可先不折腾）。

---

## 7. 常见问题排查

| 症状 | 原因与处理 |
|---|---|
| Sideloadly 报密码错误 | 必须用 **App 专用密码**（见 3.3），不是 Apple ID 密码 |
| Sideloadly 找不到设备 | 驱动问题：装/重装 Apple 官网版 iTunes 后重启；换原装数据线；手机重新点信任 |
| 手机提示"不受信任的开发者" | 见第 4 步第 3 条的信任操作 |
| 免费名额满（3 个应用上限） | 删掉别的自签应用，或等它们 7 天过期；AltStore/SideStore 自身也占名额 |
| Actions 构建失败 | Actions 页点进失败记录看红色步骤日志；把错误信息发给 ZCode |
| App 里 App Group 显示"不可用" | 主 App 与扩展没被同一证书签名安装：用 Sideloadly 整包重装一次（不要单独装） |
| 录屏列表里没有"弈眼" | App 装好后第一次需要重启手机让系统注册广播扩展；仍无则重新安装 |
| 广播开始后马上断开 | 看主 App 的"抓帧扩展日志"区，把导出日志发给 ZCode |

---

## 8. 费用与限制总结

- **0 元方案**（当前）：GitHub 公开仓库（云构建免费不限时）+ 免费 Apple ID + Sideloadly。代价：7 天重签 / 3 应用上限。
- **升级方案**（可选，$99/年）：Apple Developer 计划，签名有效期 1 年、无 3 应用限制；Sideloadly 同样适用。
- 本应用定位是**自用工具（sideload）**，不打算上架 App Store——上架需要 $99 账号且该类"旁路分析 + PiP"应用过审概率低，与 Android 版的免责声明口径一致。
