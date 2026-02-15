# ZeroClaw Nix Flake

Nix flake for [ZeroClaw](https://github.com/theonlyhennygod/zeroclaw) - Zero overhead. Zero compromise. 100% Rust. 100% Agnostic.

> **Note:** This flake was created by an AI model (Kilo Code) under the supervision of [btripoloni](https://github.com/btripoloni).

## Usage

### Run directly

```bash
nix run github:btripoloni/zeroclaw-flake

# Or with a specific command
nix run github:btripoloni/zeroclaw-flake -- agent -m "Hello"
nix run github:btripoloni/zeroclaw-flake -- gateway
nix run github:btripoloni/zeroclaw-flake -- status
```

### Install to profile

```bash
nix profile install github:btripoloni/zeroclaw-flake
zeroclaw --help
```

### Development shell

```bash
nix develop
cargo build --release
```

## Home-Manager Integration

Add this flake as an input to your home-manager configuration:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    zeroclaw.url = "github:btripoloni/zeroclaw-flake";
  };

  outputs = { self, nixpkgs, home-manager, zeroclaw }: {
    homeConfigurations."youruser" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        zeroclaw.homeManagerModules.default
        {
          services.zeroclaw = {
            enable = true;
            provider = "openrouter";
            # Use apiKeyFile for security (recommended)
            apiKeyFile = "/run/secrets/zeroclaw-api-key";
            
            # Optional: enable gateway service
            gateway = {
              enable = true;
              port = 8080;
            };
          };
        }
      ];
    };
  };
}
```

## Home-Manager Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable ZeroClaw |
| `package` | package | flake package | ZeroClaw package to use |
| `apiKey` | string | null | API key (consider apiKeyFile instead) |
| `apiKeyFile` | path | null | Path to file containing API key |
| `provider` | string | "openrouter" | AI provider |
| `model` | string | "anthropic/claude-sonnet-4-20250514" | Default model |
| `temperature` | float | 0.7 | Response temperature |
| `memory.backend` | enum | "sqlite" | Memory backend (sqlite/markdown/none) |
| `memory.autoSave` | bool | true | Auto-save memories |
| `memory.embeddingProvider` | enum | "noop" | Embedding provider (openai/noop) |
| `gateway.enable` | bool | false | Enable gateway systemd service |
| `gateway.port` | port | 8080 | Gateway port |
| `gateway.host` | string | "127.0.0.1" | Gateway host |
| `gateway.requirePairing` | bool | true | Require pairing code |
| `gateway.allowPublicBind` | bool | false | Allow public binding |
| `daemon.enable` | bool | false | Enable daemon systemd service |
| `autonomy.level` | enum | "supervised" | Autonomy level (readonly/supervised/full) |
| `autonomy.workspaceOnly` | bool | true | Restrict to workspace |
| `autonomy.allowedCommands` | list of strings | ["git", "npm", "cargo", "ls", "cat", "grep"] | Allowed shell commands |
| `workspaceDir` | path | null | Workspace directory |
| `extraConfig` | string | "" | Extra config.toml content |

## Supported Platforms

- `x86_64-linux` ✅
- `aarch64-linux` (ARM64 Linux)
- `x86_64-darwin` (macOS Intel)
- `aarch64-darwin` (macOS Apple Silicon)

## Updating

To update the ZeroClaw version:

```bash
nix flake lock --update-input zeroclaw-src
```

## License

This packaging is MIT licensed. ZeroClaw itself is also MIT licensed - see [upstream](https://github.com/theonlyhennygod/zeroclaw).
