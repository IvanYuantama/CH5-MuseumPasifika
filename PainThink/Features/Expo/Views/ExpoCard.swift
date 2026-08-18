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

            // MARK: - Location

            LocationLabel(place: entry.painting.museum)
                .padding(.top, 10)

            // MARK: - Likes

            HStack(spacing: 4) {

                Image(systemName: "heart")
                    .font(.system(size: 11))

                Text(Self.compact(entry.painting.likeCount))
                    .font(.system(size: 11))
            }
            .foregroundStyle(.black.opacity(0.45))
            .padding(.top, 2)

            // MARK: - Artwork

            ZStack {

                // White photo frame
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(
                        color: .black.opacity(0.08),
                        radius: 4,
                        x: 0,
                        y: 2
                    )

                // Artwork
                PaintingImageView(
                    assetName: entry.painting.assetName,
                    fallbackColors: insights.colorFeelings.map(\.color)
                )
                .scaledToFill()
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
                .padding(6)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(entry.aspectRatio, contentMode: .fit)
            .padding(.top, 11)
            .padding(.horizontal, 20)

            // MARK: - Headline

            if let headline = insights.headline {

                Text("\(headline.percentage)% of people say \(headline.statement)")
                    .font(
                        .system(
                            size: 14,
                            weight: .regular,
                            design: .rounded
                        )
                    )
                    .tracking(0.14)
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 10)
                    .padding(.horizontal, 20)
            }

            // MARK: - Color Feelings

            if !insights.colorFeelings.isEmpty {

                VStack(alignment: .leading, spacing: 0) {

                    Text("Color Feelings")
                        .font(
                            .system(
                                size: 11,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(.black)

                    HStack(spacing: 3) {

                        ForEach(insights.colorFeelings) { feeling in

                            Circle()
                                .fill(feeling.color)
                                .frame(
                                    width: 15,
                                    height: 15
                                )
                                .accessibilityLabel(feeling.label)
                        }
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                )
                .padding(.top, 10)
                .padding(.horizontal, 20)
            }
        }
        .padding(.horizontal, inset)
        .padding(.bottom, 15)
        .stickerCard(
            cornerRadius: 14,
            shadowOffset: CGSize(
                width: 4,
                height: 5
            )
        )
        .padding(.bottom, 10)
    }

    // Matches the "172,2 K" shorthand in the design -- Indonesian decimal comma.
    private static func compact(_ value: Int) -> String {

        guard value >= 1_000 else {
            return "\(value)"
        }

        let thousands = Double(value) / 1_000

        return String(
            format: "%.1f K",
            thousands
        )
        .replacingOccurrences(
            of: ".",
            with: ","
        )
    }
}
