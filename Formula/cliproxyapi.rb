require "digest"

class Cliproxyapi < Formula
  desc "CLIProxyAPI main with Claude encrypted-search replay recovery"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  license "MIT"
  revision 2

  head do
    url "https://github.com/router-for-me/CLIProxyAPI.git", branch: "main"

    patch do
      file "Patches/claude-search-recovery.patch"
    end
  end

  depends_on "go" => :build

  deny_network_access! [:build, :test]

  def fetch
    ENV["CGO_ENABLED"] = "1"
    system "go", "mod", "download"
    ENV["GOPROXY"] = "off"
    ENV["GOSUMDB"] = "off"

    # Homebrew's offline install phase blocks even loopback sockets. Run the mock
    # HTTP tests here, on the patched source, before the new keg can be installed.
    system "go", "test", "-tags", "debug", "./internal/runtime/executor",
           "./internal/runtime/executor/helps", "-run", "Claude", "-count=1"
  end

  def install
    ENV["CGO_ENABLED"] = "1" # Keep native shared-library plugins available.
    ENV["GOPROXY"] = "off"
    ENV["GOSUMDB"] = "off"

    patch_sha = Digest::SHA256.hexdigest(head.patches.first.contents)[0, 12]
    ldflags = %W[
      -X main.Version=#{pkg_version}-search-recovery.#{patch_sha}
      -X main.Commit=#{version.commit}
      -X main.BuildDate=#{time.iso8601}
      -X main.DefaultConfigPath=#{etc/"cliproxyapi.conf"}
    ]
    system "go", "build", "-tags", "debug", *std_go_args(ldflags:), "./cmd/server"

    # Homebrew preserves an existing config and writes changed defaults as .default.
    etc.install "config.example.yaml" => "cliproxyapi.conf"
  end

  service do
    run [opt_bin/"cliproxyapi", "--config", etc/"cliproxyapi.conf"]
    keep_alive true
    log_path var/"log/cliproxyapi.log"
    error_log_path var/"log/cliproxyapi-error.log"
  end

  test do
    output = shell_output("#{bin}/cliproxyapi --help 2>&1")
    assert_match "search-recovery", output
    assert_match "-config", output
  end
end
