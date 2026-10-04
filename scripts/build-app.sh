#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$TASK_ROOT"
scripts/swift.sh build -c release --product AttentionStack
TASK_BINARY="$TASK_ROOT/.build/release/AttentionStack"
TASK_APP="$TASK_ROOT/dist/Attention Stack.app"
mkdir -p "$TASK_APP/Contents/MacOS" "$TASK_APP/Contents/Resources"
cp "$TASK_BINARY" "$TASK_APP/Contents/MacOS/AttentionStack"
"$TASK_BINARY" --make-icon "$TASK_ROOT/.build/AttentionStack.iconset"
/usr/bin/iconutil -c icns "$TASK_ROOT/.build/AttentionStack.iconset" -o "$TASK_APP/Contents/Resources/AppIcon.icns"
cat > "$TASK_APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
    <key>CFBundleExecutable</key><string>AttentionStack</string>
    <key>CFBundleIdentifier</key><string>studio.attentionstack.mac</string>
    <key>CFBundleName</key><string>Attention Stack</string>
    <key>CFBundleDisplayName</key><string>Attention Stack</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST
/usr/bin/codesign --force --sign - "$TASK_APP"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$TASK_APP" "$TASK_ROOT/dist/Attention-Stack-mac.zip"
echo "已构建：$TASK_APP"
