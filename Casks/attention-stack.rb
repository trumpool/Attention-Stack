# frozen_string_literal: true

cask "attention-stack" do
  version "1.1.0"
  sha256 "f23891d589ce366e094f3b5f270061e7570672e8257b4d6e0fec974184e5a96f"

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
