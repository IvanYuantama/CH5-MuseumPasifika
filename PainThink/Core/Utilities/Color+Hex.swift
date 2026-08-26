//
//  Color+Hex.swift
//  PainThink
//

import SwiftUI
import UIKit

enum ColorAnswerSource: String, Hashable {
    case photoPalette = "photo"
    case customPicker = "picker"
    case legacy
}

struct ColorAnswer: Hashable {
    let hex: String
    let source: ColorAnswerSource

    init(hex: String, source: ColorAnswerSource) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        self.hex = "#\(cleaned.uppercased())"
        self.source = source
    }

    init?(encodedValue: String) {
        let components = encodedValue.split(separator: "|", maxSplits: 1).map(String.init)
        let source: ColorAnswerSource
        let candidate: String

        if components.count == 2, let taggedSource = ColorAnswerSource(rawValue: components[0]) {
            source = taggedSource
            candidate = components[1]
        } else {
            source = .legacy
            candidate = encodedValue
        }

        let cleaned = candidate.hasPrefix("#") ? String(candidate.dropFirst()) : candidate
        guard cleaned.count == 6, cleaned.allSatisfy(\.isHexDigit) else { return nil }

        self.hex = "#\(cleaned.uppercased())"
        self.source = source
    }

    var encodedValue: String {
        guard source != .legacy else { return hex }
        return "\(source.rawValue)|\(hex)"
    }
}

extension String {
    // Mendukung format lama "#RRGGBB" dan format baru
    // "photo|#RRGGBB" / "picker|#RRGGBB".
    var colorAnswer: ColorAnswer? {
        ColorAnswer(encodedValue: self)
    }

    var isHexColorString: Bool {
        colorAnswer != nil
    }
}

extension Color {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

// Dipakai hanya ketika user memilih warna lewat picker bebas. Swatch warna
// dari foto tidak melewati utility ini sehingga hex aslinya tetap utuh.
enum ColorGrouping {
    private static let hueSteps: Double = 12

    static func groupedHex(for hex: String) -> String {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        UIColor(Color(hex: hex)).getHue(
            &hue,
            saturation: &saturation,
            brightness: &brightness,
            alpha: &alpha
        )

        let bucketIndex = Int((Double(hue) * hueSteps).rounded()) % Int(hueSteps)
        let centreHue = Double(bucketIndex) / hueSteps
        return Color(hue: centreHue, saturation: 0.72, brightness: 0.88).hexString
    }
}
