//
//  MoodDistributionCard.swift
//  PainThink
//

import SwiftUI

// How the crowd's feelings split across moods. The bars reuse the recessed
// socket treatment from the drag-and-drop activity, so a number the user only
// reads here still looks like the thing they physically filled in earlier.
struct MoodDistributionCard: View {
    let moods: [PaintingInsights.MoodTally]

    private let barHeight: CGFloat = 10
    private let labelWidth: CGFloat = 76

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Mood pengunjung")

            VStack(spacing: 14) {
                ForEach(moods) { mood in
                    row(mood)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .stickerCard(cornerRadius: 14, shadowOffset: CGSize(width: 4, height: 5))
    }

    private func row(_ mood: PaintingInsights.MoodTally) -> some View {
        HStack(spacing: 11) {
            Text(mood.emoji)
                .font(.system(size: 22))

            Text(mood.label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black.opacity(0.8))
                .lineLimit(1)
                .frame(width: labelWidth, alignment: .leading)

            bar(share: mood.share)

            Text("\(Int((mood.share * 100).rounded()))%")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black.opacity(0.5))
                .frame(width: 40, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(mood.label): \(mood.count) dari pengunjung")
    }

    private func bar(share: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 0.90, green: 0.89, blue: 0.86))
                    .innerShadow(
                        cornerRadius: barHeight / 2,
                        color: .black.opacity(0.22),
                        radius: 3,
                        offset: CGSize(width: 0, height: 2)
                    )

                Capsule()
                    .fill(Color.color3)
                    .frame(width: max(barHeight, geo.size.width * share))
            }
        }
        .frame(height: barHeight)
    }
}
