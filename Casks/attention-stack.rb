# frozen_string_literal: true

cask "attention-stack" do
  version "1.1.2"
  sha256 "a6764e2c8074db2d6e79489e6b21c804b515376c6600a062373e51313e90e308"

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
