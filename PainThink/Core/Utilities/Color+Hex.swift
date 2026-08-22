//
//  Color+Hex.swift
//  PainThink
//

import SwiftUI
import UIKit

extension String {
    // True for a bare "#RRGGBB" answer value — the format the color quiz
    // activity's submitted answer always takes (see `PolaroidDevelopViewModel
    // .answerValue`), distinguishing it from a mood-word answer with no type
    // tag carried alongside it over the wire.
    var isHexColorString: Bool {
        let cleaned = hasPrefix("#") ? String(dropFirst()) : self
        return cleaned.count == 6 && cleaned.allSatisfy(\.isHexDigit)
    }
}

extension Color {
    var hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
