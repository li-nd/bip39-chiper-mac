# Test vectors

Conformance vectors for format **v1** live in a **separate repository** and are included in this project as a **Git submodule** at `test-vectors/`.

| Repository | Role |
|------------|------|
| [li-nd/bip39-chiper-test-vectors](https://github.com/li-nd/bip39-chiper-test-vectors) | Normative JSON vectors, export samples, bundled spec, verification guide |
| [li-nd/bip39-chiper-mac](https://github.com/li-nd/bip39-chiper-mac) (this repo) | Reference app, generator script, Xcode conformance tests |

Third-party implementations can copy or depend on the vectors repository directly — it is self-contained and does not require this app repository.

---

## Clone the app repository

Always initialize submodules when cloning:

```bash
git clone --recurse-submodules https://github.com/li-nd/bip39-chiper-mac.git
cd bip39-chiper-mac
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

After a successful init, `test-vectors/v1/manifest.json` should exist.

---

## Run conformance tests

Open the project in Xcode and run the **Bip39ChiperTests** target, or from the command line:

```bash
xcodebuild -scheme Bip39Chiper -destination 'platform=macOS' test \
  -only-testing:Bip39ChiperTests/TestVectorsTests
```

Tests load JSON from `test-vectors/v1/` relative to the repository root (see `Bip39ChiperTests/TestVectorLoader.swift`).

Optional override for a custom vectors checkout:

```bash
export BIP39_CHIPER_TEST_VECTORS_V1=/path/to/bip39-chiper-test-vectors/v1
xcodebuild -scheme Bip39Chiper -destination 'platform=macOS' test \
  -only-testing:Bip39ChiperTests/TestVectorsTests
```

If vectors are missing, tests fail with a message pointing to `git submodule update --init`.

---

## Update vectors to the latest release

Inside the app repository:

```bash
cd test-vectors
git fetch origin
git checkout main        # or a tagged release, e.g. v1.0.0
git pull
cd ..
git add test-vectors
git commit -m "Bump test-vectors submodule"
```

The app repository records **which commit** of the vectors repo it expects. Bump that pointer whenever you intentionally move to newer vectors.

---

## Regenerate vectors (maintainers)

The generator lives **in this repository** because it uses the reference Swift crypto implementation:

```bash
# from repo root, with submodule checked out
swift scripts/generate-test-vectors.swift
```

This writes into `test-vectors/v1/` (the submodule working tree). Then commit and push **in the vectors repository**, and bump the submodule pointer **in this repository**:

```bash
cd test-vectors
git add -A
git commit -m "Regenerate v1 vectors"
git push origin main
cd ..
git add test-vectors
git commit -m "Bump test-vectors submodule after regeneration"
```

If the normative algorithm changed, update `docs/algorithm-spec.md` here and `algorithm-spec-v1.md` in the vectors repo (keep them in sync).

---

## CI

GitHub Actions (and any other CI) must fetch submodules before running tests:

```yaml
- uses: actions/checkout@v4
  with:
    submodules: recursive
```

Or explicitly:

```bash
git submodule update --init --recursive
```

---

## Layout (vectors repository)

```
test-vectors/                 ← submodule mount point in this repo
  README.md
  CONFORMANCE.md              ← how to verify any v1 implementation
  v1/
    manifest.json
    algorithm-spec-v1.md
    kdf.json                  (80 cases)
    tokens.json               (100 cases)
    obfuscate.json            (96 cases)
    recovery.json             (288 cases)
    normalize.json            (70 cases)
    export.json               (15 cases)
    export-files/             (.txt samples)
```

**649 vector cases** total. See [CONFORMANCE.md](https://github.com/li-nd/bip39-chiper-test-vectors/blob/main/CONFORMANCE.md) in the vectors repository for layer-by-layer verification steps.
