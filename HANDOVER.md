# 📋 TypeJoy 项目完整交接与开发指南 (Handover Document)

> **项目状态**：全部迭代路线（Milestone 1 ~ 6）均已圆满完成！应用已安装到当前 macOS 本机 (`/Applications/TypeJoy.app`)，且通过完整真机运行与测试。

---

## 1. 项目基本信息

- **项目名称**：TypeJoy (字得其乐)
- **定位**：专为创作者打造的 macOS 极简常驻菜单栏击键统计与写作激励工具。
- **本地工程路径**：`/Users/lvpei/Work/github/TypeJoy`
- **GitHub 仓库**：`git@github.com:abstractwind/TypeJoy.git` (主分支: `main`)
- **运行环境**：macOS 13.0+ (Apple Silicon arm64 / Swift 6)
- **安装位置**：`/Applications/TypeJoy.app`
- **开发规范**：基于 GitHub 规范迭代，采用 Conventional Commits 提交代码。

---

## 2. 核心架构与功能实现一览

1. **📊 双指标模式（击键 + 智能汉字折算）**：
   - **状态栏主视图**：实时展示今日击键次数（如 `⌨️ 1,500`）。
   - **下拉详情面板**：展示 `今日击键：1,500 次` 与 `✍️ 预估汉字：约 450 ~ 500 字`（基于全拼输入规律 `3.0 ~ 3.3 键/字` 智能折算，由 `ChineseEstimator.swift` 处理）。
2. **🪙 马里奥金币庆祝（Micro-Celebrations）**：
   - **音效管理 (`SoundManager.swift`)**：使用 `AVFoundation` 预加载 `coin.wav`，毫秒级即时清脆播放；支持菜单栏一键静音切换。
   - **毛玻璃浮窗 (`CelebrationHUDWindow.swift`)**：屏幕右上角原生毛玻璃浮窗，展示 `🎉 达成 500 次击键！` 与预估汉字，淡入展示 2 秒后平滑淡出，非激活窗口且点击穿透，绝不打断打字。
   - **阶梯触发器**：默认每 500 次击键触发庆祝，支持切换为 1,000 键步长，防重防抖。
3. **📅 历史归档与跨天清零**：
   - 监听系统级 `NSCalendarDayChanged` 通知，每天 00:00 自动将昨日击键总数归档并清零今日计数。
   - 菜单栏展开即可查看**最近 7 天打卡记录**（如 `2026-10-23: 3,250 次 (约 980 ~ 1,080 字)`）。
4. **🚀 开机自启与偏好设置**：
   - 基于 macOS 13+ 原生 `SMAppService.mainApp`（`LaunchAtLoginManager.swift`），菜单中直接勾选开启或关闭。
   - 支持动态切换「里程碑庆祝间隔」（每 500 键 / 每 1,000 键）。
5. **🔒 纯粹隐私安全与权限管理**：
   - 全局按键监听仅执行计数累加，严格过滤长按连击（`isARepeat`），**0 字符采集**，零网络请求。
   - 提供辅助功能权限检测、系统弹窗引导与一键唤起系统设置。
6. **🤖 CI/CD 自动化打包**：
   - `.github/workflows/release.yml`：基于 GitHub Actions 自动化构建 macOS arm64/Universal 二进制，打包 zip 并发布 Release。

---

## 3. 已完成里程碑 (Milestones Status)

- [x] **M1: 仓库工程骨架与基础资源** (`Resources/coin.wav`, `AppIcon.icns`, `Info.plist`, `scripts/build.sh`)
- [x] **M2: MVP 核心击键监听与权限管理** (`StatsManager`, `KeystrokeMonitor`, `MenuController`, `AppDelegate`)
- [x] **M3: 里程碑激励、金币音效与毛玻璃 HUD 庆祝** (`SoundManager`, `CelebrationHUDWindow`)
- [x] **M4: 双指标（汉字折算）与最近 7 天打卡沉淀** (`ChineseEstimator`, 跨天自动归档)
- [x] **M5: macOS 开机自启与个性化设置** (`LaunchAtLoginManager`, 菜单栏偏好设置项)
- [x] **M6: GitHub Actions 自动化打包与 Release 发布** (`.github/workflows/release.yml`)

---

## 4. 常用运维与测试脚本

- **构建应用**：
  ```bash
  ./scripts/build.sh
  ```
- **安装到系统**：
  ```bash
  ./scripts/install.sh
  ```
- **自动化真实性测试与健康检查**：
  ```bash
  ./scripts/verify_app.sh
  ```
- **日志查看**：
  ```bash
  log stream --predicate 'process == "TypeJoy"' --info
  ```
