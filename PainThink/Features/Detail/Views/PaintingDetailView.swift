//
//  PaintingDetailView.swift
//  PainThink
//

import SwiftUI

struct PaintingDetailView: View {
    let painting: Painting
    let opinions: [VisitorOpinion]

    @Environment(\.dismiss) private var dismiss

    private let insights: PaintingInsights
    // Always 4 slots for the color chart: real picks first, padded out with
    // random colors when fewer than 4 distinct colors were actually picked.
    // Computed once in `init` (not a computed property) so the random padding
    // doesn't reshuffle on every body re-evaluation.
    private let displayColorFeelings: [PaintingInsights.ColorFeeling]
    // MENGUBAH INSET HALAMAN UTAMA MENJADI 60
    private let pageInset: CGFloat = 60
    
    let onGoToCollection: () -> Void
    let onGoToCamera: () -> Void
    /// Closure eksplisit untuk tombol back. Caller mengisi ini dengan `path.removeLast()`
    /// agar pop terjadi pada NavigationPath yang benar. Jika nil, fallback ke `dismiss()`.
    let onBack: (() -> Void)?
    /// Foto langsung dari kamera untuk ditampilkan sebagai hero image.
    /// Nil untuk entry yang berasal dari feed/collection (gunakan asset/URL).
    let capturedImage: UIImage?

    init(
        painting: Painting,
        opinions: [VisitorOpinion],
        onGoToCollection: @escaping () -> Void = {},
        onGoToCamera: @escaping () -> Void = {},
        onBack: (() -> Void)? = nil,
        capturedImage: UIImage? = nil
    ) {
        self.painting = painting
        self.opinions = opinions
        let insights = PaintingInsights(opinions: opinions, paletteLimit: 4)
        self.insights = insights
        self.displayColorFeelings = Self.padColorFeelings(insights.colorFeelings)
        self.onGoToCollection = onGoToCollection
        self.onGoToCamera = onGoToCamera
        self.onBack = onBack
        self.capturedImage = capturedImage
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PaintingHeroCard(
                    painting: painting,
                    opinionCount: insights.total,
                    paletteColors: insights.colorFeelings.map(\.color),
                    capturedImage: capturedImage
                )

                // Caption dipindahkan ke luar card
                VStack(alignment: .leading, spacing: 2) {
                    Text(painting.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(painting.artist)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.black)

                    Text(painting.year)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.black)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)

                if let headline = insights.headline {
                    ConsensusCard(headline: headline, total: insights.total)
                }

                if !displayColorFeelings.isEmpty {
                    ColorFeelingsCard(feelings: displayColorFeelings)
                }

                // Grup tombol bagian bawah
                VStack(spacing: 14) {
                    goToCameraButton
                    goToCollectionButton
                }
                .padding(.top, 30)
                .frame(maxWidth: .infinity) // Memastikan tombol terpusat di tengah
            }
            // Padding horizontal sekarang akan menggunakan nilai 60
            .padding(.horizontal, pageInset)
            .padding(.top, 4)
            // Clears the floating tab bar so the last card isn't trapped under it.
            .padding(.bottom, 120)
        }
        // Modifier ajaib iOS 16.4+: Halaman HANYA bisa di-scroll/bouncing jika kontennya melebihi layar
        .scrollBounceBehavior(.basedOnSize)
        .background(Color.color1.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) { backButton }
        }
        .toolbarBackground(Color.color1, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // Fills `feelings` out to 4 entries with random (non-repeating) colors
    // when fewer than 4 were actually picked, so the chart always reads as a
    // full 4-color spread rather than looking sparse/broken with 1-3 bars.
    // No-op once there are already 4 or more.
    private static func padColorFeelings(_ feelings: [PaintingInsights.ColorFeeling]) -> [PaintingInsights.ColorFeeling] {
        guard !feelings.isEmpty, feelings.count < 4 else { return feelings }

        var padded = feelings
        var usedHex = Set(feelings.map(\.hex))

        while padded.count < 4 {
            let hex = String(
                format: "#%02X%02X%02X",
                Int.random(in: 0...255), Int.random(in: 0...255), Int.random(in: 0...255)
            )
            guard usedHex.insert(hex).inserted else { continue }
            padded.append(PaintingInsights.ColorFeeling(hex: hex, label: hex, count: 0, share: 0))
        }
        return padded
    }

    private var backButton: some View {
        Button {
            if let onBack {
                // Gunakan pop eksplisit yang di-inject caller (NavigationPath.removeLast)
                onBack()
            } else {
                // Fallback untuk callers yang tidak inject onBack (ExpoView, SearchView)
                dismiss()
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Color.gray)
                .background(Color.clear)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
    
    // Menyesuaikan tombol My Collection
    private var goToCollectionButton: some View {
        Button {
            dismiss()
            // Give the NavigationStack a tick to pop before RootView transitions.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onGoToCollection()
            }
        } label: {
            Text("My collection")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
                .frame(width: 220) // Dibatasi agar tampak oval panjang
                .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .stickerCard(
            cornerRadius: 24, // Bentuk rounded/oval
            fill: Color(red: 204/255, green: 204/255, blue: 204/255) // Warna Light Gray
        )
        .accessibilityLabel("My Collection")
    }
    
    // Menyesuaikan tombol Find another painting
    private var goToCameraButton: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onGoToCamera()
            }
        } label: {
            Text("Find another painting")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.black)
                .frame(width: 220)
                .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .stickerCard(
            cornerRadius: 24, // Bentuk rounded/oval
            fill: Color.color3
        )
        .accessibilityLabel("Find Another Painting")
    }
}
