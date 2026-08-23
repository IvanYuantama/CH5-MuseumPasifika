//
//  PolaroidDevelopView.swift
//  PainThink
//

import SwiftUI
import SwiftData

struct PolaroidDevelopView: View {
    @State private var viewModel: PolaroidDevelopViewModel
    @State private var currentPage = 0
    @State private var pageHeights: [Int: CGFloat] = [:]
    @Environment(\.modelContext) private var modelContext
    let onGoToCollection: () -> Void
    let onGoToCamera: () -> Void

    init(image: UIImage, onGoToCollection: @escaping () -> Void, onGoToCamera: @escaping () -> Void) {
        _viewModel = State(initialValue: PolaroidDevelopViewModel(image: image))
        self.onGoToCollection = onGoToCollection
        self.onGoToCamera = onGoToCamera
    }

    var body: some View {
        Group {
            if viewModel.isUnlocked {
                PhotoDevelopedView(
                    image: viewModel.image,
                    title: viewModel.paintingTitle,
                    artist: viewModel.artistName,
                    year: viewModel.year,
                    location: viewModel.location,
                    captureDate: viewModel.captureDate,
                    painting: viewModel.resolvedPainting ?? Painting(
                        title: viewModel.paintingTitle,
                        artist: viewModel.artistName,
                        year: viewModel.year,
                        museum: viewModel.location
                    ),
                    matchedPaintingID: viewModel.matchedPaintingID,
                    syncTask: viewModel.syncTask,
                    onGoToCamera: onGoToCamera,
                    onGoToCollection: onGoToCollection
                )
            } else {
                developContent
            }
        }
        .animation(.easeInOut(duration: 0.35), value: viewModel.isUnlocked)
    }

    private var developContent: some View {
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
                                selectedLabel: viewModel.answers[activity.id],
                                onSelect: { moodLabel in
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
                                },
                                onHeightChange: { height in
                                    let roundedHeight = ceil(height)
                                    if pageHeights[index] != roundedHeight {
                                        pageHeights[index] = roundedHeight
                                    }
                                }
                            )
                            .padding(.horizontal, 24)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: tabViewHeight)

                    pageIndicator
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

    private var tabViewHeight: CGFloat {
        let measuredHeight = pageHeights[currentPage] ?? 0
        return max(measuredHeight, 360)
    }

}
