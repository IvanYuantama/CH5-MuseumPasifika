//
//  CollectionView.swift
//  PainThink
//

import SwiftUI

// The user's own polaroids, mocked from the sample feed until PolaroidRecord is
// wired in. Sections and picks mirror the handed-off design: My collection and
// Favorites, two uniform cards each.
struct CollectionView: View {
    private let gutter: CGFloat = 14
    private let pageInset: CGFloat = 20

    private var myCollection: [FeedEntry] {
        picks(titles: ["Girl With Pearl Earring", "The Scream"])
    }

    private var favorites: [FeedEntry] {
        picks(titles: ["The Starry Night", "Mona Lisa"])
    }

    private func picks(titles: [String]) -> [FeedEntry] {
        titles.compactMap { title in
            SampleFeed.entries.first { $0.painting.title == title }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Collection")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)

                    section(title: "My collection", entries: myCollection)
                    section(title: "Favorites", entries: favorites)
                }
                .padding(.horizontal, pageInset)
                .padding(.top, 8)
                .padding(.bottom, 120)
            }
            .background(Color.color1.ignoresSafeArea())
            .navigationDestination(for: FeedEntry.self) { entry in
                PaintingDetailView(painting: entry.painting, opinions: entry.opinions)
            }
        }
    }

    private func section(title: String, entries: [FeedEntry]) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.black)
                    .padding(.leading, 16)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.35))
            }

            HStack(alignment: .top, spacing: gutter) {
                ForEach(entries) { entry in
                    NavigationLink(value: entry) {
                        card(entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }.padding(.bottom, 20)
            .padding(.top, 16)
    }

    private func card(_ entry: FeedEntry) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            PaintingImageView(
                assetName: entry.painting.assetName,
                fallbackColors: PaintingInsights(opinions: entry.opinions).colorFeelings.map(\.color)
            )
            .frame(maxWidth: .infinity)
            .aspectRatio(0.82, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .padding(.bottom, 10)

            Text(entry.painting.title)
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(entry.painting.artist)
                .font(.system(size: 11, weight: .thin))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(entry.painting.year)
                .font(.system(size: 10, weight: .light))
                .foregroundStyle(.black)

            // UI kit gives the caption zone breathing room below the year.
            Color.clear.frame(height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .stickerCard(cornerRadius: 12, shadowOffset: CGSize(width: 4, height: 5))
    }
}

