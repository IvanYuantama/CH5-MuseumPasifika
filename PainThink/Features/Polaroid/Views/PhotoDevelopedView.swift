//
//  PhotoDevelopedView.swift
//  PainThink
//

import SwiftUI

// Shown once every develop activity is answered: the finished polaroid, a
// confirmation, and a bridge into what everyone else felt about the painting.
// Replaces the old "retake" ending -- after investing in four answers, the
// natural next step is the crowd, not the camera.
struct PhotoDevelopedView: View {
    let image: UIImage
    let title: String
    let artist: String
    let year: String
    let location: String
    let captureDate: String
    let onBackToHome: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    backRow

                    PolaroidFrameView(
                        image: image,
                        title: title,
                        artist: artist,
                        year: year,
                        location: location,
                        captureDate: captureDate,
                        isUnlocked: true,
                        progress: 1,
                        total: 1
                    )
                    .padding(.top, 28)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your photo has been developed!")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Added to your collection!")
                            .font(.system(size: 14))
                            .foregroundStyle(.black.opacity(0.65))

                        seeOpinionsButton
                            .padding(.top, 12)
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 32)
                }
                .padding(.bottom, 40)
            }
            .background(Color.color1.ignoresSafeArea())
            .navigationDestination(for: FeedEntry.self) { entry in
                PaintingDetailView(painting: entry.painting, opinions: entry.opinions)
            }
        }
    }

    private var backRow: some View {
        Button(action: onBackToHome) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                Text("Back to home")
                    .font(.system(size: 14))
            }
            .foregroundStyle(.black.opacity(0.7))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .accessibilityLabel("Back to home")
    }

    // Until detection returns real painting identity, the opinions screen is
    // fed by the same sample painting the develop flow hardcodes.
    private var seeOpinionsButton: some View {
        NavigationLink(
            value: FeedEntry(
                painting: SamplePaintings.girlWithPearlEarring,
                opinions: SamplePaintings.pearlEarringOpinions
            )
        ) {
            Text("See others opinion")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black.opacity(0.85))
                .padding(.horizontal, 22)
                .padding(.vertical, 13)
        }
        .buttonStyle(.plain)
        .stickerCard(cornerRadius: 12, fill: Color.color3)
    }
}
