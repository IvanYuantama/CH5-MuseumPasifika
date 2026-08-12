//
//  ExpoCard.swift
//  PainThink
//

import SwiftUI

// A feed tile: pin -> likes -> artwork -> what the crowd concluded -> palette.
// The same four facts the detail screen opens with, compressed to a glance.
struct ExpoCard: View {
    let entry: FeedEntry

    private let inset: CGFloat = 12

    var body: some View {
        let insights = PaintingInsights(opinions: entry.opinions)

        VStack(alignment: .leading, spacing: 0) {
            LocationLabel(place: entry.painting.museum)
                .padding(.top, inset)

            HStack(spacing: 4) {
                Image(systemName: "heart")
                    .font(.system(size: 11))
                Text(PaintingHeroCard.compact(entry.painting.likeCount))
                    .font(.system(size: 11))
            }
            .foregroundStyle(.black.opacity(0.45))
            .padding(.top, 5)

            PaintingImageView(
                assetName: entry.painting.assetName,
                fallbackColors: insights.colorFeelings.map(\.color)
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(entry.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .padding(.top, 10)

            if let headline = insights.headline {
                Text("\(headline.percentage)% pengunjung bilang \(headline.statement)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
            }

            if !insights.colorFeelings.isEmpty {
                Text("Color Feelings")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.black.opacity(0.55))
                    .padding(.top, 14)

                HStack(spacing: 7) {
                    ForEach(insights.colorFeelings) { feeling in
                        Circle()
                            .fill(feeling.color)
                            .frame(width: 15, height: 15)
                            .accessibilityLabel(feeling.label)
                    }
                }
                .padding(.top, 7)
            }
        }
        .padding(.horizontal, inset)
        .padding(.bottom, inset + 2)
        .stickerCard(cornerRadius: 12, shadowOffset: CGSize(width: 4, height: 5))
    }
}
