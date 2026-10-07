# frozen_string_literal: true

cask "attention-stack" do
  version "1.1.1"
  sha256 "c3e997753922775b494a64e8d45080543c0acbab589d222da8f01e34b33102f1"

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
