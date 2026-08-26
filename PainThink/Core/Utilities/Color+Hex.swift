//
//  Color+Hex.swift
//  PainThink
//

import SwiftUI
import UIKit

extension String {
    // Backend menyimpan jawaban warna sebagai hex murni. Dua prefix di bawah
    // hanya dibaca untuk kompatibilitas dengan data yang sempat dibuat oleh
    // build sebelumnya; semua submit baru kembali memakai "#RRGGBB".
    var normalizedColorHex: String? {
        let parts = split(separator: "|", maxSplits: 1).map(String.init)
        let candidate: String

        if parts.count == 2, parts[0] == "photo" || parts[0] == "picker" {
            candidate = parts[1]
        } else {
            candidate = self
        }

        let cleaned = candidate.hasPrefix("#") ? String(candidate.dropFirst()) : candidate
        guard cleaned.count == 6, cleaned.allSatisfy(\.isHexDigit) else { return nil }
        return "#\(cleaned.uppercased())"
    }

    var isHexColorString: Bool {
        normalizedColorHex != nil
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
