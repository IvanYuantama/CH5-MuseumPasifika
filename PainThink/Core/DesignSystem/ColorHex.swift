//
//  ColorHex.swift
//  PainThink
//

import SwiftUI

extension Color {
    // Palette entries travel as hex strings rather than `Color` values: they stay
    // Codable for the eventual backend, and they work as dictionary keys when
    // tallying which colours a crowd picked.
    init(hex: String) {
        let decodedHex = hex.colorAnswer?.hex ?? hex
        let cleaned = decodedHex.hasPrefix("#") ? String(decodedHex.dropFirst()) : decodedHex
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        self.init(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
