//
//  ExpoView.swift
//  PainThink
//

import SwiftUI

// Placeholder feed wired to real navigation, so the expo -> detail path can be
// walked before the backend exists. Two independent columns rather than a
// LazyVGrid: a grid locks each row to its tallest tile, which would flatten the
// staggered rhythm the design depends on.
struct ExpoView: View {
    let entries: [FeedEntry]

    private let gutter: CGFloat = 12
    private let pageInset: CGFloat = 16

    private var leftColumn: [FeedEntry] {
        entries.enumerated().filter { $0.offset.isMultiple(of: 2) }.map(\.element)
    }

    private var rightColumn: [FeedEntry] {
        entries.enumerated().filter { !$0.offset.isMultiple(of: 2) }.map(\.element)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    HStack(alignment: .top, spacing: gutter) {
                        column(leftColumn)
                        column(rightColumn)
                    }
                }
                .padding(.horizontal, pageInset)
                .padding(.top, 8)
                // Clears the floating tab bar that will sit over this feed.
                .padding(.bottom, 120)
            }
            .background(Color.color1.ignoresSafeArea())
            .navigationDestination(for: FeedEntry.self) { entry in
                PaintingDetailView(painting: entry.painting, opinions: entry.opinions)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(.black.opacity(0.1))
                .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 1) {
                Text("Wilgo1xx")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.85))
                Text("Maestro")
                    .font(.system(size: 12))
                    .foregroundStyle(.black.opacity(0.45))
            }

            Spacer()
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

            // Absorbs the leftover height instead of letting the cards stretch:
            // an HStack proposes full height to both columns, and without this
            // the shorter column's tiles grow to fill it.
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }
}

// CATATAN: jangan tambahkan #Preview — Previews selalu crash di project ini
// karena JIT executor gagal me-link static lib ONNX Runtime di app target.
// Detail lengkap ada di komentar bawah PaintingDetailView.swift. Pakai Cmd+R.
