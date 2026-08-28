//
//  ExportService.swift
//  Bip39Chiper
//
//  Clipboard, file export, poster rendering, and print.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

enum ExportService {
    static func shuffled<T>(_ items: [T]) -> [T] {
        var copy = items
        for i in stride(from: copy.count - 1, through: 1, by: -1) {
            let j = Int.random(in: 0...i)
            copy.swapAt(i, j)
        }
        return copy
    }

    static func exportTokens(_ tokens: [String], shuffle: Bool) -> [String] {
        shuffle ? shuffled(tokens) : tokens
    }

    static func joinTokens(_ tokens: [String]) -> String {
        tokens.joined(separator: " ")
    }

    static func tokensFileContent(tokens: [String], config: HasherConfig, wordCount: Int) -> String {
        var lines: [String] = []
        for line in config.exportSummaryLines(wordCount: wordCount) {
            lines.append("# \(line)")
        }
        lines.append(joinTokens(tokens))
        lines.append("")
        return lines.joined(separator: "\n")
    }

    /// Clears the pasteboard if its contents are unchanged after `seconds` (reduces accidental leakage).
    static func copyToPasteboard(_ text: String, clearAfter seconds: TimeInterval = 45) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        let copied = text
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            if NSPasteboard.general.string(forType: .string) == copied {
                NSPasteboard.general.clearContents()
            }
        }
    }

    @MainActor
    static func saveTextFile(content: String, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? content.write(to: url, atomically: true, encoding: .utf8)
    }

    @MainActor
    static func savePNG(_ image: NSImage, suggestedName: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { return }
        try? png.write(to: url)
    }

    static func makeTokensPoster(
        tokens: [String],
        config: HasherConfig,
        wordCount: Int,
        title: String = "BIP39 CHIPER — Tokens"
    ) -> NSImage {
        let cols = 4
        let rows = Int(ceil(Double(tokens.count) / Double(cols)))
        let cellW: CGFloat = 160
        let cellH: CGFloat = 52
        let pad: CGFloat = 28
        let headerH: CGFloat = 96
        let width = pad * 2 + CGFloat(cols) * cellW + CGFloat(cols - 1) * 12
        let height = pad * 2 + headerH + CGFloat(rows) * cellH + CGFloat(max(0, rows - 1)) * 10

        let settingsLine = config.exportSummaryInline(wordCount: wordCount)
        let countLine = "\(tokens.count) codes · same settings required to decrypt"

        let image = NSImage(size: NSSize(width: width, height: height))
        image.lockFocus()

        NSColor(calibratedRed: 0.07, green: 0.08, blue: 0.09, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
            .foregroundColor: NSColor(calibratedRed: 0.93, green: 0.62, blue: 0.28, alpha: 1)
        ]
        let subtitleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: NSColor(calibratedWhite: 0.65, alpha: 1)
        ]
        let settingsAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor(calibratedWhite: 0.82, alpha: 1)
        ]

        (title as NSString).draw(at: NSPoint(x: pad, y: height - pad - 22), withAttributes: titleAttrs)
        (countLine as NSString).draw(at: NSPoint(x: pad, y: height - pad - 44), withAttributes: subtitleAttrs)
        (settingsLine as NSString).draw(at: NSPoint(x: pad, y: height - pad - 66), withAttributes: settingsAttrs)

        let tokenFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .medium)
        let indexFont = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .bold)
        let tokenColor = NSColor(calibratedWhite: 0.95, alpha: 1)
        let indexColor = NSColor(calibratedRed: 0.93, green: 0.62, blue: 0.28, alpha: 1)
        let cellFill = NSColor(calibratedRed: 0.14, green: 0.16, blue: 0.18, alpha: 1)

        for (i, token) in tokens.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = pad + CGFloat(col) * (cellW + 12)
            let y = height - pad - headerH - CGFloat(row + 1) * cellH - CGFloat(row) * 10

            let rect = NSRect(x: x, y: y, width: cellW, height: cellH)
            cellFill.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 8, yRadius: 8).fill()

            let idx = "\(i + 1)" as NSString
            idx.draw(
                at: NSPoint(x: x + 10, y: y + cellH / 2 - 6),
                withAttributes: [.font: indexFont, .foregroundColor: indexColor]
            )
            (token as NSString).draw(
                at: NSPoint(x: x + 36, y: y + cellH / 2 - 8),
                withAttributes: [.font: tokenFont, .foregroundColor: tokenColor]
            )
        }

        image.unlockFocus()
        return image
    }

    @MainActor
    static func printImage(_ image: NSImage) {
        let view = NSImageView(image: image)
        view.frame = NSRect(origin: .zero, size: image.size)
        let info = NSPrintInfo.shared
        info.leftMargin = 36
        info.rightMargin = 36
        info.topMargin = 36
        info.bottomMargin = 36
        let op = NSPrintOperation(view: view, printInfo: info)
        op.showsPrintPanel = true
        op.run()
    }
}
