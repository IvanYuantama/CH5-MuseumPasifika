//
//  PaintingImageView.swift
//  PainThink
//

import SwiftUI

// Draws the artwork, or -- while the images aren't bundled yet -- a gradient
// mixed from the crowd's own colour feelings. The placeholder is made of the
// screen's real data, so an empty slot still says something about the painting.
struct PaintingImageView: View {
    let assetName: String?
    let fallbackColors: [Color]

    private var artwork: Image? {
        guard let assetName, UIImage(named: assetName) != nil else { return nil }
        return Image(assetName)
    }

    var body: some View {
        if let artwork {
            artwork
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var gradientColors: [Color] {
        fallbackColors.count >= 2
            ? fallbackColors
            : [.black.opacity(0.22), .black.opacity(0.06)]
    }
}
