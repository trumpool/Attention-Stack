# Attention Stack

一个原生 macOS 菜单栏专注栈。需要 macOS 14 或更新版本；本次构建适用于 Apple Silicon Mac。

## 下载安装包

下载 [Attention Stack 1.1.2 的 DMG 安装包](https://github.com/trumpool/Attention-Stack/raw/refs/heads/main/downloads/Attention-Stack-1.1.2-arm64.dmg)，双击打开，将 `Attention Stack.app` 拖到旁边的 `Applications` 文件夹，再从「应用程序」启动。安装完成后推出安装磁盘即可。

这个安装包和 Homebrew 版本使用相同的应用。当前版本尚未做 Apple Developer 公证；如果 macOS 阻止首次打开，请在「系统设置 → 隐私与安全性」中查看这次打开提示。

## 用 Homebrew 安装

```sh
brew tap trumpool/attention-stack https://github.com/trumpool/Attention-Stack.git
brew install --cask trumpool/attention-stack/attention-stack
open -a "Attention Stack"
```

安装到「应用程序」文件夹，支持 Apple Silicon、macOS 14 及以上版本。这个仓库同时提供自定义 Homebrew tap，所以首次安装需要上面的 `brew tap`。完整的安装名称也适用于 Homebrew 7 的自定义 tap 信任机制。[Homebrew tap 说明](https://docs.brew.sh/Taps)

更新：

```sh
brew update
brew upgrade --cask trumpool/attention-stack/attention-stack
```

卸载应用：

```sh
brew uninstall --cask trumpool/attention-stack/attention-stack
```

普通卸载会保留本地事项和归档。当前构建采用临时签名，尚未做 Apple Developer 公证；如果 macOS 阻止打开，请在「系统设置 → 隐私与安全性」中查看并批准这次打开。

也可以从 [版本 1.1.2 的安装包](https://github.com/trumpool/Attention-Stack/raw/refs/tags/v1.1.2/downloads/Attention-Stack-1.1.2-arm64.zip) 下载并解压。

## 从源码打开

双击 `dist/Attention Stack.app`。也可以把它拖入「应用程序」文件夹。菜单栏的叠层图标可以找回、隐藏或退出悬浮窗。应用采用本机临时签名，尚未做 Apple Developer 公证。

## 使用

- 点击顶部胶囊展开；点击右上角箭头或按 Esc 收起。
- 输入想法，按 Return 入栈。点击输入框旁的按钮，直接切换「前面 / 后面」：前面优先接续，后面按序等待。默认前面，应用会记住上次选择。新事项不会打断当前专注；没有当前事项时，第一项直接开始专注。
- 暖橙色表示放到待办最前，天蓝色表示追加到末尾。按钮箭头、小栈顶端 / 底端的高亮和输入框下的位置文字一起提示当前入栈方向。
- 勾选当前事项：自动归档，然后开始待办最前面的事项。完成提示提供短暂的「撤销」。切换入栈选项只影响后续新增事项，不改变已有待办的顺序。
- 拖动待办到绿色专注区，立即切换当前事项。原事项回到待办栈顶，专注计时暂停。
- 拖动待办到另一行之前可排序；拖到列表末尾可放到底部。每行右侧上箭头也可以切换专注。
- 拖动胶囊或展开面板的标题区域可移动整个窗口。菜单中的「回到屏幕顶部」恢复默认位置。
- 「已归档」显示每项的入栈时间、出栈时间和累计专注时长，支持搜索和 JSON 导出。
- 右键事项可以修改名称；右键归档事项可按当前所选位置再次入栈，原完成记录会保留。

收起后的胶囊位于系统菜单栏下方，避开刘海与菜单栏；展开面板会限制在当前屏幕的可用区域内。窗口在其他窗口上方显示，并支持多个桌面。系统开启「减少动态效果」时会减弱动画。

## 本地记录

真实数据：`~/Library/Application Support/Attention Stack/stack.json`

每次新增、切换、排序或完成时都会原子写入。没有联网、账号、云同步或上传。应用重启后恢复栈和归档。专注时间包含应用关闭期间仍处于当前专注的时间；等待任务只记录已实际处于专注状态的时长。

`--demo --expanded` 使用单独的演示数据目录。第一次打开正式版本时，如果已有预览记录而正式目录为空，会复制预览记录，保留预览期间录入的事项。`--qa` 使用另一个独立的测试目录。

## 构建和检查

安装 Apple Command Line Tools 后，在本目录运行：

```sh
./scripts/build-app.sh
./scripts/build-dmg.sh
./scripts/swift.sh test --disable-xctest
```

源码采用 SwiftUI / AppKit，无第三方依赖。`Package.swift` 可以在 Xcode 中打开。构建脚本对部分升级后残留旧文件的 Command Line Tools 做项目内兼容处理，不改动系统开发工具。

`build-dmg.sh` 会在 `dist/` 生成带版本号的 DMG，内含应用、「应用程序」快捷方式和安装说明。发布时将 DMG 及其 SHA-256 文件放进 `downloads/`，已经发布的文件应保持不变。

## 发布 Homebrew 更新

维护者先把 `VERSION` 改为新的三段版本号，在 Apple Silicon Mac 上运行：

```sh
./scripts/prepare-homebrew-release.sh
```

脚本构建并验证应用，生成版本化安装包、SHA-256 文件和 Cask。将这些文件提交到 `main` 后，为这个提交创建匹配的 `v<版本号>` 标签，并把 `main` 与标签一起推送。Cask 下载标签下的固定安装包，Homebrew 校验其 SHA-256；已经发布的包与标签应保持不变。这个仓库中的下载包仅包含应用，不包含任何本地事项数据。
