//
//  VisitorOpinionStrip.swift
//  PainThink
//

import SwiftUI

// The aggregates above turn people into percentages; this strip puts a few of
// them back. Bleeds past the page margin so it reads as scrollable without
// needing an affordance.
struct VisitorOpinionStrip: View {
    let opinions: [VisitorOpinion]
    var pageInset: CGFloat = 20

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(text: "Kata pengunjung")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(opinions) { opinion in
                        card(opinion)
                    }
                }
                .padding(.horizontal, pageInset)
                .padding(.vertical, 6)
            }
            .padding(.horizontal, -pageInset)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func card(_ opinion: VisitorOpinion) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 8) {
                Text(opinion.emoji)
                    .font(.system(size: 26))

                Circle()
                    .fill(Color(hex: opinion.colorHex))
                    .frame(width: 15, height: 15)
                    .overlay(Circle().stroke(.black.opacity(0.08), lineWidth: 1))
            }

            Text(opinion.moodLabel)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black.opacity(0.85))
                .lineLimit(1)

            Text(opinion.visitorName)
                .font(.system(size: 11))
                .foregroundStyle(.black.opacity(0.42))
                .lineLimit(1)

            Text(Self.relativeFormatter.localizedString(for: opinion.createdAt, relativeTo: Date()))
                .font(.system(size: 10))
                .foregroundStyle(.black.opacity(0.3))
        }
        .padding(14)
        .frame(width: 138, alignment: .leading)
        .stickerCard(cornerRadius: 12, shadowOffset: CGSize(width: 3, height: 4))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(opinion.visitorName) merasa \(opinion.moodLabel)")
    }
}
