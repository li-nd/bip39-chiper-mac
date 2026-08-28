# Bip39Chiper

**Offline macOS utility to obfuscate BIP-39 seed phrases** — turn a mnemonic into position-dependent codes you can store separately from your password, then recover the phrase later.

![Main window](docs/screenshots/1-main.png)

Documentation: **[chiper.developer.pm](https://chiper.developer.pm/)**

## Features

- Encrypt wizard: enter or generate a BIP-39 phrase, set a password, get codes
- Decrypt wizard: paste codes (any order), enter password, recover the phrase
- Import `.txt` exports and apply embedded crypto settings automatically
- Export: copy to clipboard, save `.txt`, render a PNG poster, or print
- Optional shuffle on export (order on screen vs exported file can differ)
- Settings for PBKDF2 iterations, derived key length, and default word count
- Onboarding, toast notifications, clipboard auto-clear, and blur-on-background
- 21 in-app languages with RTL support for Arabic, Hebrew, and Persian

## Quick start

```bash
brew tap li-nd/apps
brew trust li-nd/apps
brew install --cask bip39chiper
```

Or download a zip from [GitHub Releases](https://github.com/li-nd/bip39-chiper-mac/releases).

See [Install](https://chiper.developer.pm/install/) for Gatekeeper notes and building from source.

## Security note

Bip39Chiper is **obfuscation**, not encryption. It helps hide a seed phrase from casual observers when codes and password are stored separately. It is **not** a hardware wallet replacement. Read [Security](https://chiper.developer.pm/security/) before relying on it.

## Docs

| Page | Topic |
|------|--------|
| [Home](https://chiper.developer.pm/) | Overview and quick start |
| [Install](https://chiper.developer.pm/install/) | Homebrew, Releases, build from source |
| [Usage](https://chiper.developer.pm/usage/) | Encrypt/decrypt workflow with screenshots |
| [Security](https://chiper.developer.pm/security/) | Crypto overview and threat model |
| [Algorithm specification](https://chiper.developer.pm/algorithm-spec/) | Normative v1 scheme for independent implementations |
| [Test vectors](https://github.com/li-nd/bip39-chiper-test-vectors) | JSON conformance vectors (separate repo; Git submodule in this project) |
| [Troubleshooting](https://chiper.developer.pm/troubleshooting/) | Common issues |

## Development

Clone **with submodules** (required for conformance tests):

```bash
git clone --recurse-submodules https://github.com/li-nd/bip39-chiper-mac.git
```

Already cloned? Run `git submodule update --init --recursive`. See [Test vectors](https://chiper.developer.pm/test-vectors/) for updating the submodule, running tests, and regenerating vectors.

## License

[MIT](LICENSE) © [Markus Lind](https://github.com/li-nd)
