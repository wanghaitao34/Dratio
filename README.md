<p align="center">
  <img src="Dratio/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" width="128" height="128" alt="Dratio icon">
</p>

<h1 align="center">Dratio</h1>

<p align="center">
  <strong>一键调整 macOS 窗口宽高比的菜单栏工具</strong><br>
  <em>A macOS menu bar utility to resize any window to a specific aspect ratio</em>
</p>

<p align="center">
  <a href="#功能特性">功能</a> · <a href="#features">Features</a> · <a href="#安装">安装</a> · <a href="#使用方法">使用</a> · <a href="#contributing">Contributing</a> · <a href="#license">License</a>
</p>

---

## 功能特性

- **预设比例** — 16:9、16:10、4:3、1:1、3:4、9:16，点击即可应用到当前窗口
- **全局快捷键** — 无需打开菜单，随时随地切换窗口比例
- **等比缩放** — 保持当前比例放大/缩小窗口（每次 ±10%）
- **最大化适配** — 按当前比例将窗口最大化到屏幕可用区域
- **自定义快捷键** — 在设置中录制你喜欢的快捷键组合
- **开机自启** — 可选登录时自动启动
- **多语言** — 支持中文和英文
- **深色模式** — 跟随系统或手动切换浅色/深色外观
- **纯本地运行** — 无网络请求，无数据收集，所有操作完全在本地完成

## Features

- **Preset Ratios** — 16:9, 16:10, 4:3, 1:1, 3:4, 9:16 — one click to apply
- **Global Hotkeys** — Resize windows from anywhere without opening the menu
- **Proportional Scaling** — Zoom in/out while keeping the current ratio (±10% per step)
- **Maximize Fit** — Maximize the window to fill the screen at the current ratio
- **Custom Shortcuts** — Record your own key combos in Settings
- **Launch at Login** — Optionally start with macOS
- **Bilingual** — Chinese and English UI
- **Dark Mode** — Follow system or manually switch between light/dark
- **Fully Local** — No network requests, no data collection, everything stays on your Mac

## 默认快捷键 / Default Shortcuts

| 快捷键 Shortcut | 功能 Action |
|:---:|:---|
| `⌥⌘1` | 16:9 |
| `⌥⌘2` | 16:10 |
| `⌥⌘3` | 4:3 |
| `⌥⌘4` | 1:1 |
| `⌥⌘5` | 3:4 |
| `⌥⌘6` | 9:16 |
| `⌥⌘=` | 放大 / Zoom In (+10%) |
| `⌥⌘-` | 缩小 / Zoom Out (-10%) |
| `⌥⌘M` | 最大化适配 / Maximize Fit |

所有快捷键均可在设置中自定义。  
All shortcuts are customizable in Settings.

## 安装

### 从源码构建 / Build from Source

需要 **Xcode 16+** 和 **macOS 15.4+**。

1. 克隆仓库：

```bash
git clone https://github.com/wanghaitao34/Dratio.git
cd Dratio
```

2. 用 Xcode 打开项目：

```bash
open Dratio.xcodeproj
```

3. 选择 **My Mac** 作为目标设备，点击 **Run** (⌘R) 即可。

## 使用方法

### 1. 授予辅助功能权限

首次启动时，Dratio 会引导你授予 **辅助功能权限**（Accessibility）。这是 macOS 的要求 — Dratio 需要通过 Accessibility API 来读取和调整其他应用窗口的位置与大小。

前往 **系统设置 → 隐私与安全性 → 辅助功能**，找到 Dratio 并开启。

### 2. 调整窗口比例

- 点击你想调整的窗口，使其成为当前活跃窗口
- 点击菜单栏的 Dratio 图标（或使用快捷键 `⌥⌘1`~`⌥⌘6`）
- 窗口会立即调整为选定的宽高比

### 3. 缩放与最大化

- `⌥⌘=` / `⌥⌘-`：保持当前比例，逐步放大或缩小窗口
- `⌥⌘M`：将窗口以当前选定比例最大化到屏幕可用区域

### 4. 自定义快捷键

打开 **设置**，点击任意快捷键的显示区域，然后按下你想要的组合键即可完成录制。

## Usage

### 1. Grant Accessibility Permission

On first launch, Dratio will guide you to grant **Accessibility** permission. This is required by macOS so that Dratio can read and resize windows of other apps via the Accessibility API.

Go to **System Settings → Privacy & Security → Accessibility**, find Dratio, and toggle it on.

### 2. Resize a Window

- Click the window you want to resize to make it the frontmost window
- Click the Dratio icon in the menu bar (or use shortcuts `⌥⌘1`–`⌥⌘6`)
- The window will instantly resize to the chosen aspect ratio

### 3. Scale & Maximize

- `⌥⌘=` / `⌥⌘-`: Scale the window up/down while preserving its ratio
- `⌥⌘M`: Maximize the window to fit the screen at the current ratio

### 4. Custom Shortcuts

Open **Settings**, click on any shortcut display area, then press your desired key combination to record it.

## 系统要求 / Requirements

- macOS 15.4 (Sequoia) or later
- Accessibility permission required

## 技术栈 / Tech Stack

- **SwiftUI** — App UI and menu bar extra
- **Accessibility API** (AXUIElement) — Window manipulation
- **Carbon Events** — Global hotkey registration
- **SMAppService** — Launch at login

## 项目结构 / Project Structure

```
Dratio/
├── DratioApp.swift        # App entry, menu bar scene, AppState
├── MenuView.swift         # Menu bar dropdown UI
├── WindowManager.swift    # AXUIElement-based window resizing
├── HotKeyManager.swift    # Global hotkey registration (Carbon)
├── RatioPreset.swift      # Ratio definitions & size calculations
├── SettingsView.swift     # Settings window (shortcuts, general, permissions)
├── OnboardingView.swift   # First-launch onboarding
├── HelpView.swift         # Usage help window
├── PermissionHelper.swift # Accessibility permission check & request
└── Localizable.xcstrings  # Chinese & English localization
```

## Contributing

欢迎贡献！无论是 Bug 报告、功能建议还是 Pull Request，都非常欢迎。

Contributions are welcome! Whether it's bug reports, feature requests, or pull requests.

1. Fork 本仓库 / Fork this repo
2. 创建你的分支 / Create your branch: `git checkout -b feature/my-feature`
3. 提交更改 / Commit changes: `git commit -m "Add my feature"`
4. 推送 / Push: `git push origin feature/my-feature`
5. 提交 Pull Request / Open a Pull Request

## License

[MIT](LICENSE) — 自由使用、修改和分发。Free to use, modify, and distribute.
