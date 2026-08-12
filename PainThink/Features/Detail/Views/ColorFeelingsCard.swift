//
//  ColorFeelingsCard.swift
//  PainThink
//

import SwiftUI

// The four dots from the expo card, given room to breathe. They overlap like
// stacked chips so the palette reads as one object the crowd built together,
// rather than four unrelated swatches in a row.
struct ColorFeelingsCard: View {
    let feelings: [PaintingInsights.ColorFeeling]

    private let swatch: CGFloat = 54

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionLabel(text: "Color Feelings")

            HStack(spacing: -12) {
                ForEach(Array(feelings.enumerated()), id: \.element.id) { index, feeling in
                    Circle()
                        .fill(feeling.color)
                        .frame(width: swatch, height: swatch)
                        .overlay(Circle().stroke(Color.color2, lineWidth: 3))
                        .zIndex(Double(feelings.count - index))
                        .accessibilityLabel(feeling.label)
                }

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .stickerCard(cornerRadius: 14, shadowOffset: CGSize(width: 4, height: 5))
    }
}
