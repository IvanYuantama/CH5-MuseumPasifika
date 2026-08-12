//
//  PolaroidDevelopView.swift
//  PainThink
//

import SwiftUI
import SwiftData

struct PolaroidDevelopView: View {
    @State private var viewModel: PolaroidDevelopViewModel
    @State private var currentPage = 0
    @Environment(\.modelContext) private var modelContext
    let onDismiss: () -> Void

    init(image: UIImage, onDismiss: @escaping () -> Void) {
        _viewModel = State(initialValue: PolaroidDevelopViewModel(image: image))
        self.onDismiss = onDismiss
    }

    private var isLastActivity: Bool {
        currentPage == viewModel.activities.count - 1
    }

    var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    PolaroidFrameView(
                        image: viewModel.image,
                        title: viewModel.paintingTitle,
                        artist: viewModel.artistName,
                        year: viewModel.year,
                        location: viewModel.location,
                        captureDate: viewModel.captureDate,
                        isUnlocked: viewModel.isUnlocked,
                        progress: viewModel.completedCount,
                        total: viewModel.activities.count
                    )
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                    TabView(selection: $currentPage) {
                        ForEach(Array(viewModel.activities.enumerated()), id: \.element.id) { index, activity in
                            ActivityCardView(
                                activity: activity,
                                selectedLabel: viewModel.answers[activity.id]
                            ) { moodLabel in
                                withAnimation {
                                    viewModel.select(moodLabel, for: activity)
                                }
                                if index < viewModel.activities.count - 1 {
                                    Task {
                                        try? await Task.sleep(nanoseconds: 400_000_000)
                                        withAnimation {
                                            currentPage = index + 1
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 250)

                    pageIndicator

                    if isLastActivity {
                        retakeButton
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                }
                .padding(.bottom, 15)
            }
        }
        .task {
            await viewModel.start(context: modelContext)
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.activities.indices, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.color3 : Color.black.opacity(0.15))
                    .frame(width: index == currentPage ? 7 : 6, height: index == currentPage ? 7 : 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: currentPage)
    }

    private var retakeButton: some View {
        Button(action: onDismiss) {
            Text("Ambil Foto Lagi")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.black.opacity(0.85))
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .stickerCard(cornerRadius: 12, fill: Color.color3)
    }
}
