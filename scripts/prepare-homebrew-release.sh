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
    echo "The Homebrew package currently requires an Apple Silicon build machine." >&2
    exit 1
fi
TASK_NAME="Attention-Stack-$TASK_VERSION-arm64.zip"
TASK_PACKAGE="$TASK_ROOT/downloads/$TASK_NAME"
if [[ -e "$TASK_PACKAGE" ]]; then
    echo "Package $TASK_NAME already exists. Choose a new VERSION before publishing another build." >&2
    exit 1
fi

scripts/build-app.sh
/usr/bin/codesign --verify --deep --strict "dist/Attention Stack.app"
if [[ "$(/usr/bin/lipo -archs 'dist/Attention Stack.app/Contents/MacOS/AttentionStack')" != "arm64" ]]; then
    echo "The package must contain an arm64 executable." >&2
    exit 1
fi
mkdir -p downloads Casks
cp dist/Attention-Stack-mac.zip "$TASK_PACKAGE"
TASK_SHA="$(/usr/bin/shasum -a 256 "$TASK_PACKAGE" | awk '{print $1}')"
(cd downloads && /usr/bin/shasum -a 256 "$TASK_NAME" > "$TASK_NAME.sha256")
cat > Casks/attention-stack.rb <<CASK
# frozen_string_literal: true

cask "attention-stack" do
  version "$TASK_VERSION"
  sha256 "$TASK_SHA"

  url "https://raw.githubusercontent.com/trumpool/Attention-Stack/v#{version}/downloads/Attention-Stack-#{version}-arm64.zip"
  name "Attention Stack"
  desc "Floating focus stack with local task history"
  homepage "https://github.com/trumpool/Attention-Stack"

  livecheck do
    url "https://github.com/trumpool/Attention-Stack.git"
    strategy :git
  end

  depends_on arch: :arm64
  depends_on macos: :sonoma

  app "Attention Stack.app"

  caveats <<~EOS
    This build is ad-hoc signed and not notarized by Apple.
    If macOS blocks opening it, review it in System Settings > Privacy & Security.

    Launch with:
      open -a "Attention Stack"
  EOS
end
CASK
echo "Prepared $TASK_NAME and Casks/attention-stack.rb."
echo "Commit these files, create tag v$TASK_VERSION, then push the commit and tag together."
