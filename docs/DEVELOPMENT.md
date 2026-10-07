# 开发与发布

[返回 README](../README.md)

## 从源码打开

先按下面的构建命令生成应用，再双击 `dist/Attention Stack.app`。也可以把它拖入「应用程序」文件夹。菜单栏的叠层图标可以找回、隐藏或退出悬浮窗。应用采用本机临时签名，尚未做 Apple Developer 公证。

## 本地记录与演示模式

真实数据：`~/Library/Application Support/Attention Stack/stack.json`

每次新增、切换、排序或完成时都会原子写入。没有联网、账号、云同步或上传。应用重启后恢复栈和归档。专注时间包含应用关闭期间仍处于当前专注的时间；等待任务只记录已实际处于专注状态的时长。

`--demo --expanded` 使用单独的演示数据目录。第一次打开正式版本时，如果已有预览记录而正式目录为空，会复制预览记录，保留预览期间录入的事项。`--qa` 使用另一个独立的测试目录。

## 构建和检查

安装 Apple Command Line Tools 后，在仓库根目录运行：

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
