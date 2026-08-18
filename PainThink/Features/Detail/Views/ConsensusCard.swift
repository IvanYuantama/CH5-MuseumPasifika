//
//  ConsensusCard.swift
//  PainThink
//

import SwiftUI

// The "98% of people say..." line from the expo cards, promoted to the loudest
// thing on the screen. The percentage carries the hierarchy by scale alone --
// everything around it stays deliberately quiet.
struct ConsensusCard: View {
    let headline: PaintingInsights.Headline
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(headline.percentage)%")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(.black)
                .contentTransition(.numericText())

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.color3)
                .frame(width: 46, height: 4)
                .padding(.top, 4)

            Text("of people say \(headline.statement)")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.black.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(headline.percentage) percent of people say \(headline.statement)"
        )
        .padding(.top, 25)
        .padding(.bottom, 35)
    }
}
