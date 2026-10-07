#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$TASK_ROOT"
TASK_VERSION="$(cat VERSION)"
if [[ ! "$TASK_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "VERSION must contain a version such as 1.0.0." >&2
    exit 1
fi
if [[ "$(uname -m)" != "arm64" ]]; then
    echo "The DMG package currently requires an Apple Silicon build machine." >&2
    exit 1
fi

scripts/build-app.sh
TASK_APP="$TASK_ROOT/dist/Attention Stack.app"
/usr/bin/codesign --verify --deep --strict "$TASK_APP"
if [[ "$(/usr/bin/lipo -archs "$TASK_APP/Contents/MacOS/AttentionStack")" != "arm64" ]]; then
    echo "The package must contain an arm64 executable." >&2
    exit 1
fi
TASK_STAGE="$(mktemp -d "$TASK_ROOT/.build/dmg-stage.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT
chmod 755 "$TASK_STAGE"
/usr/bin/ditto "$TASK_APP" "$TASK_STAGE/Attention Stack.app"
ln -s /Applications "$TASK_STAGE/Applications"
cat > "$TASK_STAGE/安装说明.txt" <<'TEXT'
Attention Stack 安装

1. 将 Attention Stack.app 拖到 Applications（应用程序）文件夹。
2. 从「应用程序」打开 Attention Stack，顶部会出现专注面板。
3. 安装完成后，在 Finder 侧边栏推出 Attention Stack 安装磁盘。

需要 Apple Silicon Mac（M 系列芯片）和 macOS 14 或更新版本。
应用可以离线运行，事项和归档保存在本机。

当前版本尚未完成 Apple Developer 公证。如果 macOS 阻止首次打开，
请在「系统设置 → 隐私与安全性」中查看这次打开提示。

项目主页：https://github.com/trumpool/Attention-Stack
TEXT
TASK_DMG="$TASK_ROOT/dist/Attention-Stack-$TASK_VERSION-arm64.dmg"
/usr/bin/hdiutil create -volname "Attention Stack $TASK_VERSION" \
    -srcfolder "$TASK_STAGE" -format UDZO -fs HFS+ -ov "$TASK_DMG"
/usr/bin/hdiutil verify "$TASK_DMG"
echo "Built $TASK_DMG"
