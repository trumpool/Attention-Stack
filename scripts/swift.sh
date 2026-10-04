#!/bin/bash
set -euo pipefail
TASK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$TASK_ROOT"
TASK_TOOLCHAIN="$(xcode-select -p)/usr"
TASK_PM="$TASK_TOOLCHAIN/lib/swift/pm/ManifestAPI"
TASK_FRAMEWORKS="$(xcode-select -p)/Library/Developer/Frameworks"
if [ "${1:-}" = "test" ] && [ -d "$TASK_FRAMEWORKS/Testing.framework" ]; then
    set -- "$@" -Xswiftc -F -Xswiftc "$TASK_FRAMEWORKS" -Xlinker -rpath -Xlinker "$TASK_FRAMEWORKS"
    if [ ! -d "$TASK_FRAMEWORKS/_Testing_Foundation.framework/Modules" ]; then
        set -- "$@" -Xswiftc -Xfrontend -Xswiftc -disable-cross-import-overlays
    fi
fi

# Some upgraded Command Line Tools retain Swift 5 private interfaces beside
# Swift 6 libraries. Work around that inside this project, without system edits.
if [ -f "$TASK_PM/PackageDescription.swiftmodule/arm64-apple-macos.private.swiftinterface" ] &&
   /usr/bin/grep -q 'swiftLanguageModes' "$TASK_PM/PackageDescription.swiftmodule/arm64-apple-macos.swiftinterface" &&
   ! /usr/bin/grep -q 'swiftLanguageModes' "$TASK_PM/PackageDescription.swiftmodule/arm64-apple-macos.private.swiftinterface"; then
    mkdir -p .build/manifest-runtime
    cp -R "$TASK_PM" .build/manifest-runtime/
    for TASK_ARCH in arm64 x86_64; do
        cp ".build/manifest-runtime/ManifestAPI/PackageDescription.swiftmodule/$TASK_ARCH-apple-macos.swiftinterface" \
           ".build/manifest-runtime/ManifestAPI/PackageDescription.swiftmodule/$TASK_ARCH-apple-macos.private.swiftinterface"
    done
    export SWIFTPM_CUSTOM_LIBS_DIR="$TASK_ROOT/.build/manifest-runtime"
fi

TASK_OLD_MAP="$TASK_TOOLCHAIN/include/swift/module.modulemap"
TASK_NEW_MAP="$TASK_TOOLCHAIN/include/swift/bridging.modulemap"
if [ -f "$TASK_OLD_MAP" ] && [ -f "$TASK_NEW_MAP" ] &&
   /usr/bin/grep -q 'module SwiftBridging' "$TASK_OLD_MAP" &&
   /usr/bin/grep -q 'module SwiftBridging' "$TASK_NEW_MAP"; then
    mkdir -p .build/toolchain-overlay
    : > .build/toolchain-overlay/empty.modulemap
    /usr/bin/python3 - "$TASK_OLD_MAP" "$TASK_ROOT" <<'PY'
import json, pathlib, sys
root = pathlib.Path(sys.argv[2]) / '.build/toolchain-overlay'
(root / 'overlay.json').write_text(json.dumps({
    'version': 0,
    'roots': [{'type': 'file', 'name': sys.argv[1],
               'external-contents': str(root / 'empty.modulemap')}]
}))
PY
    swift "$@" -Xswiftc -vfsoverlay -Xswiftc "$TASK_ROOT/.build/toolchain-overlay/overlay.json" \
        -Xcc -ivfsoverlay -Xcc "$TASK_ROOT/.build/toolchain-overlay/overlay.json"
else
    swift "$@"
fi
