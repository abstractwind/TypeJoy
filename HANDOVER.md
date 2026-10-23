# 📋 TypeJoy 项目交接与继续迭代指南 (Handover Document)

> **使用方法**：在新 Session 中直接把本文档路径或下方的 **「新 Session 启动 Prompt」** 发送给 AI 助手，即可无缝继续开发。

---

## 1. 项目基本信息

- **项目名称**：TypeJoy (字得其乐)
- **定位**：专为创作者打造的 macOS 极简常驻菜单栏击键统计与写作激励工具。
- **本地工程路径**：`/Users/lvpei/Work/github/TypeJoy`
- **GitHub 仓库**：`git@github.com:abstractwind/TypeJoy.git` (主分支: `main`)
- **运行环境**：macOS 13.0+ (Apple Silicon arm64 / Swift 6)
- **开发规范**：基于 GitHub 规范迭代，采用 Conventional Commits 提交代码。

---

## 2. 核心架构与功能决策

1. **📊 双指标模式（方案 C）**：
   - **状态栏主视图**：实时展示今日击键次数（如 `⌨️ 1,500`），直观感受敲击正反馈。
   - **下拉详情面板**：按中文拼音输入规律（约 3.0~3.3 键/字）折算预估汉字量（如 `✍️ 预估汉字：约 450 ~ 500 字`）。
2. **🪙 马里奥金币庆祝（Micro-Celebrations）**：
   - 阶梯里程碑：默认每 **500** 或 **1,000** 次击键触发庆祝。
   - 听觉：播放经典的 8-bit 清脆马里奥金币音效（已内置在 `Resources/coin.wav`）。
   - 视觉：屏幕右上角弹出原生半透明毛玻璃 HUD 庆祝浮窗（展示达成次数与字数），2 秒后优雅淡出。
3. **🚀 系统级集成与开机自启**：
   - 基于 macOS 13+ 原生 `SMAppService.mainApp` 实现开机自动启动，菜单项一键开关。
   - `LSUIElement = true` 纯菜单栏应用，不占用 Dock 栏。
4. **🔒 纯粹隐私安全**：
   - 严格的 **0 按键内容采集**，仅在底层的 `NSEvent.addGlobalMonitorForEvents` 回调中执行 `count += 1`，不存储任何字符，零网络请求。
5. **📅 跨天自动重置与历史**：
   - 监听 `NSCalendarDayChanged`，每天 00:00 自动归档昨日数据并清零。
   - 菜单栏可回顾**最近 7 天打卡记录**。

---

## 3. 当前工程状态 (Current Status)

### ✅ 已完成：Milestone 1 (工程骨架与基础资源)
已推送到 GitHub `main` 分支（Commit: `31e88f2`）：
- `Resources/coin.wav`：已生成的高清马里奥金币音效（44.1kHz 16-bit PCM）。
- `Resources/AppIcon.icns`：已生成的 512x512 高分辨率应用图标。
- `Resources/Info.plist`：配置了 `LSUIElement = true` 与应用元数据。
- `scripts/build.sh`：自动化 Swift 编译、Bundle 组装与本地 Ad-hoc 代码签名脚本。
- `.gitignore`：已忽略 `build/`、`.DS_Store` 等产物。
- `LICENSE`：MIT 开源协议。
- `README.md`：项目概述与路线图。

---

## 4. 下一步任务 (Next Tasks)

### 🎯 即刻开展：Milestone 2 (MVP 核心击键监听与权限管理)
按顺序实现以下源文件（均位于 `Sources/` 目录）：
1. **`Sources/StatsManager.swift`**：
   - 今日计数持久化（`UserDefaults`）
   - 击键更新事件通知闭包 `onCountChanged`
2. **`Sources/KeystrokeMonitor.swift`**：
   - 辅助功能权限检测（`AXIsProcessTrusted()`）
   - 全局按键监听器（`NSEvent.addGlobalMonitorForEvents(matching: [.keyDown])`，过滤 `event.isARepeat`）
   - 引导跳转系统设置方法（`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`）
3. **`Sources/MenuController.swift`**：
   - `NSStatusItem` 状态栏图标初始化，实时更新标题 `⌨️ <count>`
   - 下拉菜单（展示今日击键数、辅助功能权限状态、退出菜单）
4. **`Sources/AppDelegate.swift` & `Sources/main.swift`**：
   - `NSApp.setActivationPolicy(.accessory)`
   - 协调 Controller 与 Monitor 的生命周期
5. **编译与验证**：
   - 执行 `./scripts/build.sh` 编译出 `build/TypeJoy.app` 并本地测试。
6. **Git 提交并推送**：
   - `feat: implement core keystroke monitoring and status bar item (M2)`

---

## 5. 后续迭代路线

- **M3 (音效与 HUD 弹窗)**：实现 `SoundManager.swift`（播放 `coin.wav`）与 `CelebrationHUDWindow` 毛玻璃气泡。
- **M4 (双指标与历史归档)**：汉字智能折算算法、跨天通知监听与最近 7 天数据存储展示。
- **M5 (开机自启与设置)**：实现 `LaunchAtLoginManager.swift`（`SMAppService`）与完整菜单交互。
- **M6 (CI/CD 自动化)**：配置 `.github/workflows/release.yml`，在 GitHub 自动打包发布 Release。
