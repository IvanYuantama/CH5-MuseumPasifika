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

                if !insights.colorFeelings.isEmpty {
                    ColorFeelingsCard(feelings: insights.colorFeelings)
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
