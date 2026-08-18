//
//  PaintingDetailView.swift
//  PainThink
//

import SwiftUI

// What opens when an expo or collection card is tapped: one painting, and what
// everybody who scanned it felt about it.
//
// Reads top to bottom as artwork -> verdict -> breakdown -> individuals, so the
// screen answers "what is this" before "what do people think" before "who".

struct PaintingDetailView: View {
    let painting: Painting
    let opinions: [VisitorOpinion]

    @Environment(\.dismiss) private var dismiss

    private let insights: PaintingInsights
    private let pageInset: CGFloat = 20
    let onGoToCollection: () -> Void
    let onGoToCamera: () -> Void

    init(
        painting: Painting,
        opinions: [VisitorOpinion],
        onGoToCollection: @escaping () -> Void = {},
        onGoToCamera: @escaping () -> Void = {}
    ) {
        self.painting = painting
        self.opinions = opinions
        self.insights = PaintingInsights(opinions: opinions)
        self.onGoToCollection = onGoToCollection
        self.onGoToCamera = onGoToCamera
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PaintingHeroCard(
                    painting: painting,
                    opinionCount: insights.total,
                    paletteColors: insights.colorFeelings.map(\.color)
                )

                if let headline = insights.headline {
                    ConsensusCard(headline: headline, total: insights.total)
                }

//                if !insights.moods.isEmpty {
//                    MoodDistributionCard(moods: insights.moods)
//                }

                if !insights.colorFeelings.isEmpty {
                    ColorFeelingsCard(feelings: insights.colorFeelings)
                }

//                if !opinions.isEmpty {
//                    VisitorOpinionStrip(opinions: opinions, pageInset: pageInset)
//                        .padding(.top, 4)
//                        .padding(.bottom, 10)
//                }
                goToCameraButton
                goToCollectionButton
            }
            .padding(.horizontal, pageInset)
            .padding(.top, 4)
            // Clears the floating tab bar so the last card isn't trapped under it.
            .padding(.bottom, 120)
        }
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
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.black.opacity(0.75))
                .frame(width: 34, height: 34)
                .background(Color.color2, in: Circle())
                .overlay(Circle().stroke(.black.opacity(0.08), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }
    
    private var goToCollectionButton: some View {
        Button {
            dismiss()
            // Give the NavigationStack a tick to pop before RootView transitions.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onGoToCollection()
            }
        } label: {
            Text("Go to Collection")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .stickerCard(cornerRadius: 12)
        .accessibilityLabel("Go to Collection")
    }
    
    private var goToCameraButton: some View {
        Button {
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                onGoToCamera()
            }
        } label: {
            Text("Find Another Painting")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .stickerCard(
            cornerRadius: 12,
            fill: .yellow
        )
        .accessibilityLabel("Find Another Painting")
    }
}

// CATATAN: jangan tambahkan #Preview di project ini.
// Xcode Previews SELALU crash ("Attempt to use unknown class", OBJC code 1)
// karena JIT executor Previews gagal me-link static library ONNX Runtime yang
// nempel di app target — bahkan preview Text kosong pun crash (sudah dibuktikan
// di worktree bersih tanpa file UI). Lihat UI lewat Cmd+R (root = RootView).

