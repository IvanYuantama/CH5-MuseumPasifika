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
    let painting: Painting
    let onGoToCamera: () -> Void
    let onGoToCollection: () -> Void
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
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
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.black)
                            .fixedSize(horizontal: false, vertical: true)

                        // CTAs: see opinions (navigates within the stack) and
                        // go to collection (pops back to the collection screen).
                        HStack {
                            seeOpinionsButton
                            Spacer()
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 36)
                    .padding(.top, 32)
                }
                .padding(.bottom, 40)
            }
            .background(Color.color1.ignoresSafeArea())
            .navigationDestination(for: FeedEntry.self) { entry in
                PaintingDetailView(
                    painting: entry.painting,
                    opinions: entry.opinions,
                    onGoToCollection: onGoToCollection,
                    onGoToCamera: onGoToCamera
                )
            }
        }
    }

    // Opinions aren't served by the backend yet, so the detail screen opens
    // with the real, on-device-resolved painting but no crowd opinions.
    private var seeOpinionsButton: some View {
        NavigationLink(
            value: FeedEntry(
                painting: painting,
                opinions: []
            )
        ) {
            Text("See what other saw")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
        .stickerCard(cornerRadius: 8, shadowOffset: CGSize(width: 2, height: 3), fill: Color.color3)
    }

    
}
