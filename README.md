# Attention Stack

[中文](#中文) · [English](#english)

## 中文

一个原生 macOS 悬浮专注栈。随手记下想法，一次专注一件事，完成后自动接续下一项。

支持 **Apple Silicon（M 系列）Mac，macOS 14 及以上**。

### 安装

[下载 DMG 安装包 · v1.1.2](https://github.com/trumpool/Attention-Stack/raw/refs/heads/main/downloads/Attention-Stack-1.1.2-arm64.dmg)

双击打开，把 `Attention Stack.app` 拖进 `Applications`，再从「应用程序」启动。

也可以使用 Homebrew：

```sh
brew tap trumpool/attention-stack https://github.com/trumpool/Attention-Stack.git
brew install --cask trumpool/attention-stack/attention-stack
open -a "Attention Stack"
```

当前构建采用临时签名，尚未做 Apple 公证。如果 macOS 阻止首次打开，请在「系统设置 → 隐私与安全性」中查看这次打开提示。

### 使用

- 输入想法，按 Return 入栈，不打断当前专注。
- 点击按钮切换入栈位置：**暖橙色「前面」**优先接续，**天蓝色「后面」**按序等待。箭头和小栈高亮提示落点，应用会记住选择。
- 勾选当前事项：自动归档，开始待办最前面的事项；完成提示支持短暂撤销。
- 拖动待办到专注区可立即切换；拖动列表中的事项可调整顺序。
- 点击顶部胶囊展开，按 Esc 收起；拖动标题区域移动窗口。
- 归档包含入栈时间、出栈时间和专注时长，支持搜索、JSON 导出及再次入栈。

**离线使用，无需账号。** 事项和归档只保存在本机，重启后恢复。数据位置：`~/Library/Application Support/Attention Stack/stack.json`。专注时长会包含应用关闭期间当前事项仍处于专注的时间。

### 更新

DMG 安装的用户：下载新版，退出应用，再替换「应用程序」中的旧版本。事项和归档会保留。

Homebrew 安装的用户：

```sh
brew update
brew upgrade --cask trumpool/attention-stack/attention-stack
```

## English

A native floating focus stack for macOS. Capture thoughts, focus on one task at a time, and move to the next task automatically when you finish.

Requires an **Apple Silicon Mac and macOS 14 or later**.

### Install

[Download the DMG installer · v1.1.2](https://github.com/trumpool/Attention-Stack/raw/refs/heads/main/downloads/Attention-Stack-1.1.2-arm64.dmg)

Open the DMG, drag `Attention Stack.app` into `Applications`, then launch it from Applications.

Or install with Homebrew:

```sh
brew tap trumpool/attention-stack https://github.com/trumpool/Attention-Stack.git
brew install --cask trumpool/attention-stack/attention-stack
open -a "Attention Stack"
```

This build is ad-hoc signed and is not notarized by Apple. If macOS blocks the first launch, review the prompt in **System Settings → Privacy & Security**.

### Use

- Type a thought and press Return to add it without interrupting your current task.
- Click the position button to switch between **orange Front (前面)** for priority and **blue Back (后面)** for waiting in order. Arrows and a stack marker show the destination. Your choice is remembered.
- Check off the current task to archive it and start the first waiting task. A brief undo option is available.
- Drag a waiting task into the focus area to start it, or drag tasks within the list to reorder them.
- Click the top pill to expand, press Esc to collapse, and drag the header to move the window.
- The archive records enqueue and completion times, plus focus duration. Search, export to JSON, or repeat an archived task.

**Works offline. No account required.** Tasks and history stay on your Mac and are restored when you reopen the app. Data is stored at `~/Library/Application Support/Attention Stack/stack.json`. Focus duration includes time while the app is closed if the task remains current.

### Update

For DMG installations, download the new version, quit the app, and replace the old copy in Applications. Your tasks and archive are preserved.

For Homebrew installations:

```sh
brew update
brew upgrade --cask trumpool/attention-stack/attention-stack
```

## 开发 / Development

Built with SwiftUI and AppKit, with no third-party dependencies. Install Apple Command Line Tools, then run:

```sh
./scripts/build-app.sh
./scripts/build-dmg.sh
./scripts/swift.sh test --disable-xctest
```

[开发与发布说明 / Development and release guide (中文)](docs/DEVELOPMENT.md)
