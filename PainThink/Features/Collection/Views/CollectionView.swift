//
//  CollectionView.swift
//  PainThink
//

import SwiftUI

// The user's own polaroids, mocked from the sample feed until PolaroidRecord is
// wired in. Sections and picks mirror the handed-off design: My collection and
// Favorites, two uniform cards each.
struct CollectionView: View {
    let onCameraTap: () -> Void
    private let horizontalSpacing: CGFloat = 15
    private let verticalSpacing: CGFloat = 15
    private let pageInset: CGFloat = 20

    // NavigationPath eksplisit agar tombol back di PaintingDetailView bisa pop ke CollectionView
    @State private var navPath = NavigationPath()

    // All 6 sample entries used as dummy gallery items.
    private var myCollection: [FeedEntry] { SampleFeed.entries }

    // Toggle to false to see the empty state during development.
    private var hasItems: Bool { !myCollection.isEmpty }

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                if hasItems {
                    filledContent
                } else {
                    emptyContent
                }

                // Dedicated bottom area for the camera button so cards NEVER scroll behind it.
                HStack {
                    Spacer()
                    cameraFAB
                        .padding(.trailing, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                }
                .background(Color.color1)
            }
            .background(Color.color1.ignoresSafeArea())
        }
    }

    // MARK: - Content states

    private var filledContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // FIXED HEADER
            Text("Gallery")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, pageInset)
                .padding(.top, 8)

            Text("My Gallery")
                .font(.system(size: 18, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .padding(.leading, pageInset + 20)
                .padding(.top, 24)
                .padding(.bottom, 20)

            // ONLY THIS PART SCROLLS
            ScrollView {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: horizontalSpacing),
                        GridItem(.flexible(), spacing: horizontalSpacing)
                    ],
                    spacing: verticalSpacing
                ) {
                    ForEach(myCollection) { entry in
                        CollectionCardView(entry: entry)
                    }
                }
                .padding(.horizontal, pageInset)
                .padding(.bottom, 20)
            }
            .background(Color.color1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.color1.ignoresSafeArea())
        .navigationDestination(for: FeedEntry.self) { entry in
            PaintingDetailView(
                painting: entry.painting,
                opinions: entry.opinions,
                onGoToCollection: { /* already in collection, no-op */ },
                onGoToCamera: onCameraTap,
                // Back button pop dari navPath ini → kembali ke My Collection
                onBack: { navPath.removeLast() }
            )
        }
    }

    
    private var emptyContent: some View {
        ZStack(alignment: .topLeading) {
            Color.color1.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text("Gallery")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, pageInset)
                    .padding(.top, 8)

                    .padding(.bottom,85)

                VStack(alignment: .leading, spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.color3)
                            .frame(width: 60, height: 60)

                        Image("Collection")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 33, height: 36)
                            .foregroundStyle(.white)

                    }

                    Text("No painting have\nbeen captured.")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Try to capture a painting and let it sits on\nyour gallery.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, pageInset)

                Spacer()
                Spacer()
            }
            .frame(width: 150, alignment: .topLeading)
        }
    }

    private var cameraFAB: some View {
        Button(action: onCameraTap) {
            Image("newcamera")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.18), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan a painting")
    }



}

struct CollectionCardView: View {
    let entry: FeedEntry
    @State private var isFlipped = false


    var body: some View {
        ZStack {
            frontView
                .opacity(isFlipped ? 0 : 1)
            
            backView
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isFlipped)
        .onTapGesture {
            isFlipped.toggle()
        }
    }

    // MARK: - Front View

    private var frontView: some View { polaroidFace() }

    /// Muka depan polaroid.
    /// - showsLocation: baris lokasi cuma dipasang waktu di-share, di galeri nggak.
    /// - fillsCell: di galeri kartunya ngisi penuh tinggi sel; waktu di-render
    ///   jadi gambar, tingginya harus ngikut isi, kalau nggak hasilnya melar.
    private func polaroidFace(showsLocation: Bool = false,
                              fillsCell: Bool = true) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            PaintingImageView(
                assetName: entry.painting.assetName,
                imageURLString: entry.painting.imageURLString,
                fallbackColors: PaintingInsights(opinions: entry.opinions).colorFeelings.map(\.color),
                contentMode: .fit
            )
            .frame(maxWidth: .infinity)
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

            if showsLocation {
                LocationLabel(place: MuseumInfo.currentName, size: 10)
                    .padding(.top, 8)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 12)
        .padding(.bottom, 12)
        // maxHeight bikin kartu putih ngisi penuh tinggi sel. Tanpa ini tinggi sel
        // ditentukan backView (yang lebih tinggi), sisanya jadi celah krem — itu
        // yang bikin jarak vertikal keliatan jauh lebih lebar dari horizontal.
        .frame(maxWidth: .infinity,
               maxHeight: fillsCell ? .infinity : nil,
               alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .stickerCard(
            cornerRadius: 10,
            shadowOffset: CGSize(width: 4, height: 5)
        )

    }

    // MARK: - Back View

    private var backView: some View {

        VStack(alignment: .leading, spacing: 14) {

            Text(shortTitle(for: entry.painting.title))
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.black)

            let insight = PaintingInsights(opinions: entry.opinions)
            let circleColor = insight.colorFeelings.first?.color ?? Color.color3

            Circle()
                .fill(circleColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 6) {

                Text(insight.moods.first?.label ?? "Warm")
                    .font(
                        .system(
                            size: 18,
                            weight: .regular,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)

                Text("Feel Safe")
                    .font(
                        .system(
                            size: 18,
                            weight: .regular,
                            design: .rounded
                        )
                    )
                    .foregroundStyle(.black)
                    .padding(.bottom, 2)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.color3)
                            .frame(height: 2)
                    }
            }

            Spacer(minLength: 20)

            HStack {

                NavigationLink(value: entry) {
                    Text("Details")
                        .font(
                            .system(
                                size: 18,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .foregroundStyle(.black)
                        .padding(.bottom, 2)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(Color.color3)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: sharePolaroid) {
                    ZStack {
                        Circle()
                            .fill(Color.color3)
                            .frame(width: 42, height: 42)

                        Image(systemName: "square.and.arrow.up")
                            .font(
                                .system(
                                    size: 18,
                                    weight: .semibold
                                )
                            )
                            .foregroundStyle(.white)
                            .offset(y: -1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(
            width: 150,
            alignment: .topLeading
        )
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 24)
        )
        .stickerCard(
            cornerRadius: 24,
            shadowOffset: CGSize(width: 4, height: 5)
        )
    }

    private func shortTitle(for title: String) -> String {
        if title == "Girl With Pearl Earring" { return "A Pearl" }
        let words = title.split(separator: " ")
        return String(words.prefix(2).joined(separator: " "))
    }

    // Creates an image of the front of the polaroid card for sharing
    @MainActor
    private func sharePolaroid() {
        // Polaroid yang sama kayak di galeri, cuma ditambah baris lokasi —
        // sengaja cuma muncul di hasil share, galerinya tetap bersih.
        let card = polaroidFace(showsLocation: true, fillsCell: false)
            .frame(width: 300)

        let renderer = ImageRenderer(content: card)
        renderer.scale = UIScreen.main.scale

        if let image = renderer.uiImage {
            let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(activityVC, animated: true)
            }
        }
    }
}

