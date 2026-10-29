class Cliproxyapi < Formula
  desc "CLIProxyAPI main with Claude encrypted-search replay recovery"
  homepage "https://github.com/router-for-me/CLIProxyAPI"
  license "MIT"

  head do
    url "https://github.com/router-for-me/CLIProxyAPI.git", branch: "main"

    patch do
      file "Patches/claude-search-recovery.patch"
    end
  end

  depends_on "go" => :build

  # The regression tests use local HTTP servers, including signed OAuth retries.
  allow_network_access! :build

  def fetch
    system "go", "mod", "download"
  end

  def install
    ENV["CGO_ENABLED"] = "1" # Keep native shared-library plugins available.
    ENV["GOPROXY"] = "off"
    ENV["GOSUMDB"] = "off"

    # This gate runs during installation, before the new keg can replace the old one.
    system "go", "test", "-tags", "debug", "./internal/runtime/executor",
           "./internal/runtime/executor/helps", "-run", "Claude", "-count=1"

    ldflags = %W[
      -X main.Version=#{version}-search-recovery
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
