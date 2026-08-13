//
//  SearchView.swift
//  PainThink
//

import SwiftUI

// Search over the expo feed by title, artist, or museum. The result grid is the
// same masonry + ExpoCard as the expo screen, so a found painting looks exactly
// like it does everywhere else and opens the same detail.
struct SearchView: View {
    let entries: [FeedEntry]

    @State private var query = ""

    private let gutter: CGFloat = 12
    private let pageInset: CGFloat = 16

    private var results: [FeedEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter { entry in
            entry.painting.title.localizedCaseInsensitiveContains(trimmed)
                || entry.painting.artist.localizedCaseInsensitiveContains(trimmed)
                || entry.painting.museum.localizedCaseInsensitiveContains(trimmed)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Search")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.black)

                    HStack(spacing: 10) {
                        searchField
                        micButton
                    }

                    if results.isEmpty {
                        emptyState
                    } else {
                        grid
                    }
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

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField("Search something...", text: $query)
                .font(.system(size: 14))
                .submitLabel(.search)
                .autocorrectionDisabled()

            Image("Search")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .opacity(0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .stickerCard(cornerRadius: 22, shadowOffset: CGSize(width: 3, height: 4))
    }

    // Visual only for now; speech input is a later phase.
    private var micButton: some View {
        Button {
        } label: {
            Image(systemName: "mic")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.black.opacity(0.8))
                .frame(width: 44, height: 44)
                .stickerCard(cornerRadius: 22, shadowOffset: CGSize(width: 2, height: 3))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Voice search")
    }

    private var grid: some View {
        HStack(alignment: .top, spacing: gutter) {
            column(results.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element))
            column(results.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element))
        }
    }

    private func column(_ items: [FeedEntry]) -> some View {
        VStack(spacing: 5) {
            ForEach(items) { entry in
                NavigationLink(value: entry) {
                    ExpoCard(entry: entry)
                }
                .buttonStyle(.plain)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("No results for \"\(query)\"")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black.opacity(0.7))

            Text("Maybe you're the first one to find it.")
                .font(.system(size: 13))
                .foregroundStyle(.black.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}
