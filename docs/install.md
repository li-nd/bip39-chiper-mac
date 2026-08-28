# Install

Bip39Chiper is a **macOS-only** SwiftUI app. It is not distributed via the Mac App Store.

You can install it with **Homebrew** or by **downloading a zip from GitHub Releases**.

## Homebrew

```bash
brew tap li-nd/apps
brew trust li-nd/apps
brew install --cask bip39chiper
```

Tap: [li-nd/homebrew-apps](https://github.com/li-nd/homebrew-apps). Requires **macOS Tahoe** or newer (matches the app’s deployment target).

### Upgrade / uninstall

```bash
brew update
brew upgrade --cask bip39chiper
brew uninstall --cask bip39chiper
```

## GitHub Releases

1. Open [GitHub Releases](https://github.com/li-nd/bip39-chiper-mac/releases).
2. Download the latest macOS zip (for example `Bip39Chiper-x.y.z-macos.zip`).
3. Unzip and move `Bip39Chiper.app` to `/Applications` (or another folder you prefer).
4. Launch the app.

Use Releases if you prefer not to use Homebrew, or if you need a specific version.

## Notarization / Gatekeeper

Current Bip39Chiper builds are **ad-hoc signed and not notarized**. On first launch macOS may block the app — this applies to both Homebrew and Releases installs.

Workaround:

1. **System Settings → Privacy & Security → Open Anyway**, or
2. Right-click the app in Finder → **Open** → confirm.

This project does **not** claim App Store or official Homebrew Cask compliance. Same policy as other apps in the [li-nd/homebrew-apps](https://github.com/li-nd/homebrew-apps) tap.

## Build from source

1. Clone the repository **with submodules** (needed for unit tests):
   ```bash
   git clone --recurse-submodules https://github.com/li-nd/bip39-chiper-mac.git
   cd bip39-chiper-mac
   ```
   If you already cloned without submodules: `git submodule update --init --recursive`.
2. Open `Bip39Chiper.xcodeproj` in Xcode.
3. Select the **Bip39Chiper** scheme and a Mac destination.
4. Run (`⌘R`).

Requires a recent Xcode with a macOS SDK matching the project settings.

Conformance tests load vectors from the [bip39-chiper-test-vectors](https://github.com/li-nd/bip39-chiper-test-vectors) submodule at `test-vectors/`. See [Test vectors](test-vectors.md).

## Dependencies

Bip39Chiper has **no** Homebrew CLI prerequisites. All crypto runs locally; the app does not connect to the network.

## Preview documentation locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-docs.txt
mkdocs serve
```

Open the URL printed by MkDocs (usually `http://127.0.0.1:8000/`).
