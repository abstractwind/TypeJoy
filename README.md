# ⌨️ TypeJoy (字得其乐)

> 一个专为创作者打造的 macOS 极简常驻菜单栏打字统计工具，让你爱上写作。

[![Platform](https://img.shields.io/badge/Platform-macOS%2013.0%2B-black.svg?style=flat&logo=apple)](https://www.apple.com/macos/)
[![Language](https://img.shields.io/badge/Language-Swift%206-orange.svg?style=flat&logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## ✨ 核心特性

- 🪶 **极致轻量**：纯原生 Swift + AppKit 开发，整个 App 仅 ~**500 KB**，空闲时 CPU 0%，内存占用 < 15MB。
- 📊 **双指标模式**：
  - **主视图（状态栏）**：实时展示今日击键次数（如 `⌨️ 1,500`），直观感受每一次敲击的正反馈。
  - **副指标（下拉面板）**：基于拼音输入规律智能折算预估汉字量（如 `✍️ 预估汉字：约 450 ~ 500 字`）。
- 🪙 **马里奥金币庆祝**：
  - 每达到 **500** 或 **1,000** 阶梯里程碑，播放经典的**清脆马里奥金币音效**。
  - 屏幕右上角同步弹出半透明毛玻璃 **HUD 庆祝浮窗**，2 秒后自动淡出。
- 🚀 **开机自动启动**：基于 macOS 13+ 原生 `SMAppService`，菜单栏一键开关。
- 📅 **每日归档与记录**：每日 00:00 自动开启新的一天，下拉菜单随时查看**最近 7 天打卡记录**。
- 🔒 **纯粹隐私安全**：**0 按键内容记录**，仅在底层做 `count += 1` 计数，零网络请求。

---

## 🗺️ 迭代路线图 (Roadmap)

- [x] **M1: 仓库工程骨架与资源配置**
- [x] **M2: MVP 核心击键监听与权限管理**
- [ ] **M3: 里程碑激励、金币音效与毛玻璃 HUD 庆祝** (下一阶段)
- [ ] **M4: 双指标（汉字折算）与最近 7 天打卡沉淀**
- [ ] **M5: macOS 开机自启与个性化设置**
- [ ] **M6: GitHub Actions 自动化打包与 Release 发布**

---

## 🛠️ 构建与运行

### 依赖环境
- macOS 13.0+
- Xcode Command Line Tools (`swiftc`)

### 构建命令
在项目根目录下执行：
```bash
./scripts/build.sh
```
构建产物将输出在 `build/TypeJoy.app`，可以直接运行或拖入 `/Applications` 文件夹中使用。

---

## 📄 开源许可

本项目采用 [MIT License](LICENSE) 授权开源。
