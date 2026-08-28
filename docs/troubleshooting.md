# Troubleshooting

## macOS blocked the app

Current Bip39Chiper builds are **ad-hoc signed and not notarized**. On first launch (Homebrew or a zip from Releases) macOS may block the app.

Workaround:

1. **System Settings → Privacy & Security → Open Anyway**, or
2. Right-click the app in Finder → **Open** → confirm.

See [Install](install.md) for details.

---

## Wrong password / token not found

During decrypt, each code must match the lookup table derived from your password and settings.

- **Token not found** — wrong password, wrong iterations/key size, or typo in a code
- **Password mismatch** — password changed mid-flow vs cached lookup
- Double-check **Settings → Encryption** matches the `#` headers in your export file
- Re-import the `.txt` file to apply embedded settings automatically

Minimum password length is **8 characters**.

---

## Invalid token format

Codes must be exactly **9 characters** from the allowed alphabet after normalization:

```text
23456789ABCDEFGHJKMNPQRSTVWXYZ
```

Common mistakes:

- Confusing `0`/`O` or `1`/`I`/`L` — these letters are excluded from codes; if you typed them, fix the source
- Missing characters from a bad OCR or manual copy
- Pasting words instead of codes

---

## Ambiguous token or slot conflict

Rare HMAC truncations can map two different `(position, word)` pairs to the same 9-character code. The app stops with an explicit error instead of guessing.

If this happens:

1. Confirm you are using the intended **format version** (`v1`)
2. Try re-encrypting with different settings (higher key size does not change token length; re-encrypting the same phrase with the same settings reproduces the same codes)
3. Report the issue with phrase length and settings (never share real seed phrases)

---

## Import failed

| Error | Cause |
|-------|--------|
| Unreadable | File encoding or permissions |
| Empty | File has no content |
| No tokens | Headers only, or no valid token line |

Expected format:

```text
# version: v1
# words: 24
# iterations: 600000
# keyBytes: 32
TOKEN1 TOKEN2 ...
```

Tokens can also be imported without headers if Settings already match.

---

## Settings differ from export

When importing, Bip39Chiper compares `# words`, `# version`, `# iterations`, and `# keyBytes` to your current defaults and shows a diff. Tap **Apply** to sync before decrypting.

Imported iterations are applied **verbatim** (not snapped to the nearest UI preset).

---

## Clipboard cleared unexpectedly

After **Copy**, the pasteboard auto-clears after about **45 seconds** if its contents were not changed. This is intentional. Copy again if you still need the text.

---

## UI blurred in background

Sensitive screens blur when the app loses focus. Bring Bip39Chiper to the front to read content again.

---

## Decrypt is slow

First entry builds a lookup table of `phraseLength × 2048` tokens. Longer phrases and higher PBKDF2 iterations increase wait time. Subsequent tokens in the same session reuse a cached table.

Typical defaults (24 words, 600k iterations) run in a few seconds on recent Macs.

---

## Shuffle vs what I wrote down

On-screen codes on the encrypt result are in **position order**. If **Shuffle on export** was enabled, a copied or saved file may list codes in a different order. Decryption still works — order does not matter.

When backing up on paper from the **Poster** or **Print** action, the grid order matches what you see on screen (numbered 1…N).

---

## Language / RTL layout

Arabic, Hebrew, and Persian use right-to-left layout. If text looks misaligned, update to the latest build or switch language in **Settings → General**.

---

## Preview documentation locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-docs.txt
mkdocs serve
```

Open the URL printed by MkDocs (usually `http://127.0.0.1:8000/`).

---

## Still stuck?

Open an issue on [GitHub](https://github.com/li-nd/bip39-chiper-mac/issues) with:

- macOS version
- Bip39Chiper version (About window)
- Crypto settings (iterations, key bytes, word count)
- Steps to reproduce

**Never** include real seed phrases, passwords, or production codes in bug reports.
