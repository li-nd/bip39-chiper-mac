//
//  BIP39Mnemonic.swift
//  Bip39Chiper
//
//  BIP-39 mnemonic generation and checksum validation.
//

import CryptoKit
import Foundation
import Security

enum MnemonicWordCount: Int, CaseIterable, Identifiable, Hashable {
    case twelve = 12
    case fifteen = 15
    case eighteen = 18
    case twentyOne = 21
    case twentyFour = 24

    var id: Int { rawValue }

    /// Byte length of entropy for this word count (BIP-39: ENT bits = words × 32 / 3).
    var entropyByteCount: Int {
        (rawValue * 32 / 3) / 8
    }

    var label: String {
        L10n.wordCountLabel(self)
    }
}

enum BIP39Error: LocalizedError {
    case randomGenerationFailed
    case invalidEntropyLength
    case wordlistCorrupted
    case invalidWord(String)
    case invalidChecksum

    var errorDescription: String? {
        switch self {
        case .randomGenerationFailed:
            return L10n.errorRandomGenerationFailed
        case .invalidEntropyLength:
            return L10n.errorInvalidEntropyLength
        case .wordlistCorrupted:
            return L10n.errorWordlistCorrupted
        case .invalidWord(let word):
            return L10n.errorInvalidWordBIP39(word)
        case .invalidChecksum:
            return L10n.errorInvalidChecksum
        }
    }
}

enum BIP39Mnemonic {
    static func generate(wordCount: MnemonicWordCount) throws -> [String] {
        guard BIP39Wordlist.words.count == 2048 else {
            throw BIP39Error.wordlistCorrupted
        }

        var entropy = [UInt8](repeating: 0, count: wordCount.entropyByteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, entropy.count, &entropy)
        guard status == errSecSuccess else {
            throw BIP39Error.randomGenerationFailed
        }

        return try mnemonicWords(fromEntropy: Data(entropy))
    }

    static func mnemonicWords(fromEntropy entropy: Data) throws -> [String] {
        let entBits = entropy.count * 8
        guard [128, 160, 192, 224, 256].contains(entBits) else {
            throw BIP39Error.invalidEntropyLength
        }

        let checksumBitCount = entBits / 32
        let hash = SHA256.hash(data: entropy)
        let hashBytes = Array(hash)

        var bits = [Bool]()
        bits.reserveCapacity(entBits + checksumBitCount)

        for byte in entropy {
            for shift in stride(from: 7, through: 0, by: -1) {
                bits.append(((byte >> shift) & 1) == 1)
            }
        }

        // Append the first ENT/32 bits of SHA-256(entropy) as the checksum.
        let firstHashByte = hashBytes[0]
        for shift in stride(from: 7, through: 7 - checksumBitCount + 1, by: -1) {
            bits.append(((firstHashByte >> shift) & 1) == 1)
        }

        let wordCount = (entBits + checksumBitCount) / 11
        var words = [String]()
        words.reserveCapacity(wordCount)

        for wordIndex in 0..<wordCount {
            let start = wordIndex * 11
            var index = 0
            for bitOffset in 0..<11 {
                index <<= 1
                if bits[start + bitOffset] {
                    index |= 1
                }
            }
            words.append(BIP39Wordlist.words[index])
        }

        return words
    }

    static func validate(_ words: [String]) throws {
        guard let wordCount = MnemonicWordCount(rawValue: words.count) else {
            throw BIP39Error.invalidEntropyLength
        }
        _ = wordCount

        var indexByWord: [String: Int] = [:]
        indexByWord.reserveCapacity(BIP39Wordlist.words.count)
        for (index, word) in BIP39Wordlist.words.enumerated() {
            indexByWord[word] = index
        }

        var bits = [Bool]()
        bits.reserveCapacity(words.count * 11)

        for word in words {
            guard let index = indexByWord[word] else {
                throw BIP39Error.invalidWord(word)
            }
            for shift in stride(from: 10, through: 0, by: -1) {
                bits.append(((index >> shift) & 1) == 1)
            }
        }

        let entBits = words.count * 32 / 3
        let checksumBitCount = entBits / 32
        let entropyBitCount = bits.count - checksumBitCount

        var entropy = [UInt8](repeating: 0, count: entropyBitCount / 8)
        for i in 0..<entropyBitCount {
            if bits[i] {
                entropy[i / 8] |= UInt8(1 << (7 - (i % 8)))
            }
        }

        let hash = SHA256.hash(data: Data(entropy))
        let hashByte = Array(hash)[0]
        for i in 0..<checksumBitCount {
            let expected = ((hashByte >> (7 - i)) & 1) == 1
            if bits[entropyBitCount + i] != expected {
                throw BIP39Error.invalidChecksum
            }
        }
    }
}
