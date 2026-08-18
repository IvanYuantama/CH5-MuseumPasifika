//
//  PaintingHeroCard.swift
//  PainThink
//

import SwiftUI

// The expo card, opened up: same pin -> artwork -> caption rhythm, but with the
// artwork given room to be looked at instead of scanned past.
struct PaintingHeroCard: View {
    let painting: Painting
    let opinionCount: Int
    let paletteColors: [Color]

    private let inset: CGFloat = 16

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaintingImageView(
                assetName: painting.assetName,
                imageURLString: painting.imageURLString,
                fallbackColors: paletteColors
            )
            .frame(maxWidth: .infinity)
            .frame(height: 360)
            .padding(.horizontal, inset)
            .padding(.top, inset)
            .padding(.bottom, 40)
        }
        .frame(width: 273)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .stickerCard(
            cornerRadius: 24,
            shadowOffset: CGSize(width: 4, height: 5)
        )
    }
}
