# vfox-iii-engine

A [vfox](https://vfox.dev/) plugin for installing and managing the [III engine](https://github.com/iii-hq/iii).

> III is a workflow engine for building interactive applications.

## Usage

### Install the plugin

```bash
# via mise (recommended)
mise plugin install iii-engine <git-url>

# or via vfox
vfox add iii-engine <git-url>
```

### Install a version of III

```bash
# Install the latest version
mise i iii-engine

# Install a specific version
mise i iii-engine@0.21.4

# List available remote versions
mise ls-remote iii-engine

# List installed versions
mise ls iii-engine

# Use a specific version in the current project
mise use iii-engine@0.21.4
```

After installation, the `iii` command will be available in your PATH.

## Supported Platforms

| OS | Architecture | Target |
|---|---|---|
| macOS | Intel (amd64) | `x86_64-apple-darwin` |
| macOS | Apple Silicon (arm64) | `aarch64-apple-darwin` |
| Linux | amd64 | `x86_64-unknown-linux-gnu` |
| Linux | arm64 | `aarch64-unknown-linux-gnu` |
| Linux | armv7 | `armv7-unknown-linux-gnueabihf` |
| Windows | amd64 | `x86_64-pc-windows-msvc` |
| Windows | arm64 | `aarch64-pc-windows-msvc` |

## How it works

This plugin scrapes the [III releases page](https://github.com/iii-hq/iii/releases) to discover available versions. For each version, it automatically selects the correct binary archive for your current platform, verifies the SHA256 checksum, and extracts the `iii` binary.

## Development

```bash
# syntax check all Lua files
luac -p metadata.lua lib/util.lua hooks/*.lua
```

## License

Apache 2.0
