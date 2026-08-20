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
    /// Foto langsung dari kamera — ditampilkan sebagai hero image jika ada.
    var capturedImage: UIImage? = nil

    private let inset: CGFloat = 16
    private let cardWidth: CGFloat = 273
    // Lebar konkret yang diketahui oleh scaledToFit() untuk menghitung height relatif
    private var photoWidth: CGFloat { cardWidth - inset * 2 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PaintingImageView(
                assetName: painting.assetName,
                imageURLString: painting.imageURLString,
                fallbackColors: paletteColors,
                uiImage: capturedImage,
                contentMode: .fit
            )
            // frame(width:) konkret → scaledToFit() dapat menghitung height dari aspect ratio asli
            .frame(width: photoWidth)
            .clipShape(RoundedRectangle(cornerRadius: 2))
            .padding(.horizontal, inset)
            .padding(.top, inset)
            .padding(.bottom, 40)
        }
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)
        )
        .stickerCard(
            cornerRadius: 3,
            shadowOffset: CGSize(width: 4, height: 5)
        )
    }
}
