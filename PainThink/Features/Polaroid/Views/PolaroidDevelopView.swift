//
//  PolaroidDevelopView.swift
//  PainThink
//

import SwiftUI
import SwiftData

struct PolaroidDevelopView: View {
    @State private var viewModel: PolaroidDevelopViewModel
    @Environment(\.modelContext) private var modelContext
    let onDismiss: () -> Void

    init(image: UIImage, onDismiss: @escaping () -> Void) {
        _viewModel = State(initialValue: PolaroidDevelopViewModel(image: image))
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color.galleryBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    PolaroidFrameView(
                        image: viewModel.image,
                        isUnlocked: viewModel.isUnlocked,
                        progress: viewModel.completedCount,
                        total: viewModel.activities.count,
                        caption: viewModel.detectedLabel
                    )
                    .padding(.top, 24)

                    VStack(spacing: 16) {
                        ForEach(Array(viewModel.activities.enumerated()), id: \.element.id) { index, activity in
                            ActivityCardView(
                                activity: activity,
                                index: index + 1,
                                selectedLabel: viewModel.answers[activity.id]
                            ) { moodLabel in
                                withAnimation {
                                    viewModel.select(moodLabel, for: activity)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    Button("Ambil Foto Lagi") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.brass)
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            await viewModel.start(context: modelContext)
        }
    }
}
