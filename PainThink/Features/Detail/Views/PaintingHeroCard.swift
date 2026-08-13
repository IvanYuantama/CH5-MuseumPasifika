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
            LocationLabel(place: painting.museum)
                .padding(.horizontal, inset)
                .padding(.top, inset)

            PaintingImageView(assetName: painting.assetName, fallbackColors: paletteColors)
                .frame(maxWidth: .infinity)
                .frame(height: 340)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .padding(.horizontal, inset)
                .padding(.top, 12)

            caption
                .padding(.horizontal, inset)
                .padding(.top, 18)

            Divider()
                .background(.black.opacity(0.06))
                .padding(.horizontal, inset)
                .padding(.top, 16)

            statRow
                .padding(.horizontal, inset)
                .padding(.top, 12)
                .padding(.bottom, 18)
        }
        .stickerCard(cornerRadius: 14, shadowOffset: CGSize(width: 5, height: 6))
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(painting.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(painting.artist) · \(painting.year)")
                .font(.museumCaption(.subheadline))
                .foregroundStyle(.black.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statRow: some View {
        HStack(spacing: 18) {
            stat(systemImage: "heart", value: painting.likeCount, label: "likes")
            stat(systemImage: "bubble.left", value: opinionCount, label: "opinions")
            Spacer()
        }
    }

    private func stat(systemImage: String, value: Int, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
            Text(Self.compact(value))
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundStyle(.black.opacity(0.45))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(label)")
    }

    // Matches the "172,2 K" shorthand in the design -- Indonesian decimal comma.
    static func compact(_ value: Int) -> String {
        guard value >= 1_000 else { return "\(value)" }
        let thousands = Double(value) / 1_000
        return String(format: "%.1f K", thousands).replacingOccurrences(of: ".", with: ",")
    }
}
