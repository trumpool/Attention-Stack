# frozen_string_literal: true

cask "attention-stack" do
  version "1.0.0"
  sha256 "f30533148fc963ec17bd08f4d5d2e7deb6e41adcb9430ff837f5af901a2a26e8"

  url "https://raw.githubusercontent.com/trumpool/Attention-Stack/v#{version}/downloads/Attention-Stack-#{version}-arm64.zip",
      verified: "raw.githubusercontent.com/trumpool/Attention-Stack/"
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
