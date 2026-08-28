# Positional BIP-39 Obfuscation — Format v1

**Algorithm specification**

This document defines the **Positional BIP-39 Obfuscation** scheme, format version **v1**. It is written to be **implementation-independent**: any conforming program on any platform should produce identical codes for identical inputs and recover the same mnemonic when given the correct password, parameters, and codes.

This is **obfuscation**, not encryption. The scheme is deterministic and intentionally reversible for anyone who holds both the password and the codes. For threat model and usage guidance, see [Security](security.md).

---

## 1. Scope

### 1.1 What this specification covers

- Parameter block for format v1
- Key derivation from a user password
- Token (code) generation from a BIP-39 mnemonic
- Mnemonic recovery from tokens in **any order**
- Text export file layout for interchange
- Normative error conditions

### 1.2 What this specification does not cover

- User interface, clipboard handling, or shuffle-on-export (export order randomization is a presentation concern; recovery ignores order)
- BIP-39 mnemonic **generation** (only validation on recovery — see [BIP-39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki))
- Test vectors (see [Appendix A](#appendix-a--test-vectors))
- Future format versions (v2 and above)

### 1.3 Reference implementation

The [Bip39Chiper](https://github.com/li-nd/bip39-chiper-mac) macOS application is one conforming implementation. This specification is **normative**; the app must match it, not the other way around.

---

## 2. Terminology

| Term | Definition |
|------|------------|
| **Mnemonic** | Ordered list of *N* words from the BIP-39 English wordlist |
| **N** | Mnemonic length: 12, 15, 18, 21, or 24 |
| **Position** `p` | 1-based index of a word slot in the mnemonic (1 … N) |
| **Word index** `i` | 0-based index of a word in the BIP-39 English wordlist (0 … 2047) |
| **Token** / **code** | Fixed-length string over the token alphabet; one token per mnemonic word |
| **Password** | User secret as UTF-8 bytes; never stored in export files |
| **Parameters** | `version`, `N`, `iterations`, `keyBytes` — must match between obfuscation and recovery |

---

## 3. Prerequisites

### 3.1 BIP-39 English wordlist

Implementations **MUST** use the official [BIP-39 English wordlist](https://github.com/bitcoin/bips/blob/master/bip-0039/english.txt):

- Exactly **2048** lowercase words
- Word at line *k* (1-based file line) has **word index** *k − 1*
- Mnemonic words **MUST** appear in the list; comparison is case-sensitive for storage but implementations typically normalize input to lowercase before lookup

### 3.2 Allowed mnemonic lengths

| N | Entropy bits | Checksum bits |
|---|--------------|---------------|
| 12 | 128 | 4 |
| 15 | 160 | 5 |
| 18 | 192 | 6 |
| 21 | 224 | 7 |
| 24 | 256 | 8 |

Any other value of *N* is invalid.

### 3.3 BIP-39 checksum validation

After all *N* word slots are filled during recovery, the assembled word list **MUST** pass standard BIP-39 checksum validation before being accepted as output. See BIP-39 for the algorithm (11 bits per word, checksum taken from SHA-256 of the entropy).

---

## 4. Format v1 — parameter block

| Parameter | v1 value | Notes |
|-----------|----------|-------|
| `version` | `"v1"` | Appears in HMAC payload and export headers |
| `salt` | UTF-8 `"Bip39Chiper.v1.positional-hasher"` | Fixed; not per-user random |
| `kdf` | PBKDF2 with HMAC-SHA256 as PRF | RFC 8018 |
| `iterations` | Integer ≥ 100 000 | Default **600 000**; upper bound 50 000 000 recommended |
| `keyBytes` | 16, 32, or 64 | Default **32** (256-bit key) |
| `hmac` | HMAC-SHA256 | RFC 2104 / FIPS 198-1 |
| `hmac_payload_prefix` | `"v1"` | Same string as `version` |
| `hmac_truncate_bytes` | 5 | First 5 bytes of MAC used |
| `token_length` | 8 | Character count after encoding |
| `alphabet` | see §5 | 30 characters, radix 30 |

All multi-byte integers in export files are decimal ASCII unless stated otherwise.

---

## 5. Token alphabet and encoding

### 5.1 Alphabet

30 characters, uppercase only, Crockford Base32-inspired (radix **30**, not 32):

```text
23456789ABCDEFGHJKMNPQRSTVWXYZ
```

Excluded to reduce visual ambiguity: `0`, `O`, `1`, `I`, `L`, `U`.

**Radix** = 30 (length of the alphabet string above). **Modulus** for v1 tokens: 30⁸ = 656 100 000 000.

### 5.2 EncodeFixed

Encodes up to 5 input bytes as a fixed-length string of exactly `token_length` alphabet characters.

```
function EncodeFixed(bytes[0 .. hmac_truncate_bytes-1], length):
    // Big-endian unsigned integer from bytes
    value ← 0
    for each byte b in bytes:
        value ← (value × 256) + b

    modulus ← radix ^ length          // for v1: 30^8 = 656_100_000_000

    value ← value mod modulus

    if value = 0:
        return alphabet[0] repeated length times    // "22222222" for v1

    chars ← empty list
    n ← value
    while n > 0:
        rem ← n mod radix
        append alphabet[rem] to chars
        n ← n div radix

    while length(chars) < length:
        append alphabet[0] to chars

    return reverse(chars) as a single string
```

Implementations **MUST** follow this padding and byte-order rules exactly. Off-by-one differences in encoding break interoperability.

### 5.3 Token normalization (input)

When parsing user-supplied codes:

```
function NormalizeToken(raw):
    u ← uppercase(raw)
    return concatenation of all characters in u that belong to alphabet
```

A token is **well-formed** when:

- After normalization, length = `token_length`
- Every character is in the alphabet

---

## 6. Key derivation

The symmetric key used for HMAC is derived from the password:

```
function DeriveKey(password_utf8, salt, iterations, keyBytes) → key:
    return PBKDF2-HMAC-SHA256(
        password  = password_utf8,
        salt      = salt,
        iterations = iterations,
        dkLen     = keyBytes
    )
```

| Field | v1 value |
|-------|----------|
| `password_utf8` | Password encoded as UTF-8 (no null terminator) |
| `salt` | UTF-8 bytes of `"Bip39Chiper.v1.positional-hasher"` |
| `iterations` | From parameter block |
| `keyBytes` | From parameter block |

Security note: the salt is public and identical for all users. Strength depends on password quality and iteration count. Minimum password length (8 characters) is a product recommendation, not part of the cryptographic parameter block.

---

## 7. Token generation

Each mnemonic word at position `p` with word index `i` maps to one token.

### 7.1 HMAC payload

Build a UTF-8 string:

```text
{version}:{p}:{i}
```

Example: position 3, word index 42 → `"v1:3:42"`

- `version` is the literal `"v1"`
- `p` is decimal representation with no leading zeros (except the digit `0` itself is unused because positions start at 1)
- `i` is decimal representation with no leading zeros

### 7.2 MAC and truncation

```
mac ← HMAC-SHA256(key, payload_utf8)     // 32 bytes
truncated ← mac[0 .. 4]                   // first 5 bytes
token ← EncodeFixed(truncated, token_length=8)
```

### 7.3 Position binding

The same word at different positions yields different payloads and therefore different tokens. The same `(p, i)` pair with the same key always yields the same token (deterministic obfuscation).

### 7.4 Obfuscation procedure

```
function Obfuscate(words[1 .. N], password, params) → tokens[1 .. N]:

    assert N ∈ {12, 15, 18, 21, 24}

    for p from 1 to N:
        i ← WordlistIndex(words[p])
        if i is undefined: error unknown_word

    key ← DeriveKey(password, params.salt, params.iterations, params.keyBytes)

    for p from 1 to N:
        i ← WordlistIndex(words[p])
        tokens[p] ← Token(p, i, key, params)

    return tokens
```

Output order matches mnemonic order. Export shuffling is out of scope.

---

## 8. Recovery procedure

Recovery accepts tokens in **any order**. Position is inferred from the token itself via a precomputed lookup table.

### 8.1 Lookup table construction

```
function BuildLookupTable(key, N, params) → table:

    table ← empty map: Token → list of (position, word, word_index)

    for p from 1 to N:
        for i from 0 to 2047:
            t ← Token(p, i, key, params)
            w ← WordlistWord(i)
            append (p, w, i) to table[t]

    return table
```

Complexity: *N × 2048* token computations. Implementations may cache the table for a session.

### 8.2 Token parsing

Split raw input on whitespace, commas, semicolons, and newlines. Trim empty segments. Normalize each segment with `NormalizeToken` before lookup.

### 8.3 Slot assignment

Maintain `slots[1 .. N]` (empty strings initially).

For each normalized token `t` in the input batch (order irrelevant):

```
if not WellFormed(t):
    error invalid_token_format

matches ← table[t]
if matches is empty:
    error token_not_found

free ← { m ∈ matches | slots[m.position] is empty }

if |free| = 1:
    m ← the single element of free
else if |matches| = 1:
    m ← matches[0]
else:
    error ambiguous_token

if slots[m.position] is not empty and slots[m.position] ≠ m.word:
    error slot_conflict

slots[m.position] ← m.word
```

### 8.4 Completion

When every slot is non-empty:

```
ValidateBIP39Checksum(slots[1 .. N])
return slots as recovered mnemonic
```

If validation fails → `invalid_bip39_checksum`.

Partial input (some slots still empty) is not a final result; implementations may show progress incrementally.

### 8.5 Wrong password behavior

An incorrect password derives a different key, producing a different lookup table. User tokens will almost always fail with `token_not_found`. There is no dedicated “wrong password” signal separate from token mismatch.

---

## 9. Worked example (illustrative)

The following walks through the logic **without fixed numeric outputs** (test vectors will be published separately).

**Mnemonic** (N=12, valid BIP-39, entropy `0x00…00`):

```text
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

| p | i | word | token |
|---|---|------|-------|
| 1 | 0 | abandon | `JKDEPFPN` |
| 2 | 0 | abandon | *(same word, different position → different token)* |
| … | … | … | … |
| 12 | 3 | about | *(see vectors repo `v1/obfuscate.json`)* |

Full token lists for all parameter sets are in [`v1/obfuscate.json`](https://github.com/li-nd/bip39-chiper-test-vectors/blob/main/v1/obfuscate.json).

---

## 10. Export file format

Normative interchange format: UTF-8 plain text.

### 10.1 Structure

```text
# version: v1
# words: 24
# iterations: 600000
# keyBytes: 32
TOKEN1 TOKEN2 TOKEN3 ... TOKENN
```

- **Comment lines** start with `#`. Body is `key: value` after removing leading `#` and whitespace.
- Keys are case-insensitive: `version`, `words`, `iterations`, `keybytes`.
- Values have internal spaces stripped in some parsers; write values without spaces.
- **Token line**: one or more tokens separated by ASCII whitespace, commas, or semicolons.
- Trailing newline optional.
- **Password MUST NOT appear** in the file.

### 10.2 Import behavior

A conforming importer:

1. Parses comment headers into the parameter block
2. Parses the token line
3. Uses header `words` as *N* if present
4. Applies header `iterations` and `keyBytes` if they differ from local defaults
5. Enters recovery with the parsed tokens

Tokens-only files (no headers) are valid if the caller supplies *N* and parameters explicitly.

---

## 11. Error conditions

| Error | Condition |
|-------|-----------|
| `invalid_word_count` | *N* ∉ {12, 15, 18, 21, 24} |
| `unknown_word` | Mnemonic word not in BIP-39 English wordlist |
| `invalid_token_format` | Normalized token length ≠ 8 or invalid character |
| `token_not_found` | Token absent from lookup table |
| `ambiguous_token` | Multiple table matches; cannot pick a unique unfilled slot |
| `slot_conflict` | Target slot already holds a different word |
| `invalid_bip39_checksum` | All slots filled but BIP-39 validation fails |
| `empty_password` | Password has zero length (implementations may reject) |

---

## 12. Collision analysis (informative)

- Each token draws from a space of 30⁸ ≈ 6.6 × 10¹¹ values.
- The lookup table contains *N × 2048* entries. Birthday collisions (two different `(p, i)` pairs mapping to the same token) are unlikely but possible in theory.
- Implementations **MUST NOT** guess when `ambiguous_token` occurs.
- Truncating HMAC to 40 bits per token is a usability trade-off (shorter codes), not a secrecy bound against an attacker with password + codes.

---

## 13. Interoperability checklist

Implementations claiming v1 conformance **MUST**:

- [ ] Use the exact BIP-39 English wordlist ordering
- [ ] Use 1-based positions in HMAC payloads
- [ ] Use salt `"Bip39Chiper.v1.positional-hasher"` for v1
- [ ] Use payload format `v1:{p}:{i}` with decimal *p* and *i*
- [ ] Truncate HMAC-SHA256 to the first 5 bytes before encoding
- [ ] Implement `EncodeFixed` exactly as §5.2
- [ ] Accept tokens in any order during recovery
- [ ] Validate BIP-39 checksum on complete recovery
- [ ] Reject ambiguous tokens and slot conflicts

Implementations **MAY**:

- Cache derived keys and lookup tables within a session
- Process tokens incrementally and show partial progress
- Enforce minimum password length ≥ 8
- Snap iteration counts to UI presets on export (import should accept exact header values)

---

## 14. Versioning

| Version | Status | Changes |
|---------|--------|---------|
| v1 | Current | Initial specification |

Future versions **MUST** use a different `version` string, salt, and/or payload format. Export headers record the version so importers select the correct parameter block.

---

## 15. Related documents

| Document | Content |
|----------|---------|
| [Security](security.md) | Threat model, limitations, comparison to encryption |
| [Usage](usage.md) | End-user workflow in Bip39Chiper |
| BIP-39 | Mnemonic wordlists and checksum definition |
| [Test vectors](https://github.com/li-nd/bip39-chiper-test-vectors) | Machine-readable conformance vectors (JSON) + [verification guide](https://github.com/li-nd/bip39-chiper-test-vectors/blob/main/CONFORMANCE.md) |
| [Test vectors (app repo)](test-vectors.md) | Git submodule setup and running tests in Bip39Chiper |

## Appendix A — Test vectors

Normative conformance data lives in the [bip39-chiper-test-vectors](https://github.com/li-nd/bip39-chiper-test-vectors) repository (`v1/` directory). Verification steps: [CONFORMANCE.md](https://github.com/li-nd/bip39-chiper-test-vectors/blob/main/CONFORMANCE.md). This app repo includes that repository as a Git submodule at `test-vectors/` — see [Test vectors](test-vectors.md).

| File | Cases | Purpose |
|------|-------|---------|
| `manifest.json` | — | Format version, alphabet, radix, file index |
| `algorithm-spec-v1.md` | — | Bundled copy of this specification |
| `kdf.json` | 80 | PBKDF2 key derivation (passwords, iterations, key sizes) |
| `tokens.json` | 100 | Single-token HMAC + encoding (positions 1–24, word indices) |
| `obfuscate.json` | 96 | Full mnemonic obfuscation (N = 12…24, multiple seeds/passwords) |
| `recovery.json` | 288 | Shuffled recovery (3 permutations × 96 mnemonics) |
| `normalize.json` | 70 | Token normalization |
| `export.json` | 15 | Text export parsing (`export-files/*.txt`) |

Regenerate after crypto changes: `swift scripts/generate-test-vectors.swift` (writes into the `test-vectors/` submodule — commit and push in [bip39-chiper-test-vectors](https://github.com/li-nd/bip39-chiper-test-vectors), then bump the submodule pointer here). See [Test vectors](test-vectors.md).

Third-party implementations should reproduce all `kdf.json` and `tokens.json` values exactly, and pass all `obfuscate.json` / `recovery.json` round-trips.
