//
//  ExpoCard.swift
//  PainThink
//

import SwiftUI

// A feed tile: pin -> likes -> artwork -> what the crowd concluded -> palette.
// The same four facts the detail screen opens with, compressed to a glance.
struct ExpoCard: View {
    let entry: FeedEntry

    private let inset: CGFloat = 10

    var body: some View {
        let insights = PaintingInsights(opinions: entry.opinions)

        VStack(alignment: .leading, spacing: 0) {
            LocationLabel(place: entry.painting.museum)
                .padding(.top, 10)

            HStack(spacing: 4) {
                Image(systemName: "heart")
                    .font(.system(size: 11))
                Text(PaintingHeroCard.compact(entry.painting.likeCount))
                    .font(.system(size: 11))
            }
            .foregroundStyle(.black.opacity(0.45))
            .padding(.top, 2)

            PaintingImageView(
                assetName: entry.painting.assetName,
                fallbackColors: insights.colorFeelings.map(\.color)
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(entry.aspectRatio, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .padding(.top, 11)
            .padding(.horizontal, 20)

            if let headline = insights.headline {
                Text("\(headline.percentage)% of people say \(headline.statement)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .tracking(0.14)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }

            if !insights.colorFeelings.isEmpty {
                Text("Color Feelings")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(.black)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                HStack(spacing: 3) {
                    ForEach(insights.colorFeelings) { feeling in
                        Circle()
                            .fill(feeling.color)
                            .frame(width: 15, height: 15)
                            .accessibilityLabel(feeling.label)
                    }
                }
                .padding(.top, 3)
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, inset)
        .padding(.bottom, 15)
        .stickerCard(cornerRadius: 12, shadowOffset: CGSize(width: 4, height: 5))
        .padding(.bottom, 10)
    }
}
