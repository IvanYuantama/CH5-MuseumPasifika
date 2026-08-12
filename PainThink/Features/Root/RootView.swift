//
//  RootView.swift
//  PainThink
//

import SwiftUI

// Hosts the four tabs and floats the bar over them. Camera is deliberately not a
// tab: it sits in the middle of the bar for balance but opens the capture sheet,
// matching the flow the app already had before the bar existed.
struct RootView: View {
    // Wraps the photo so it can drive `fullScreenCover(item:)` without making
    // UIKit's UIImage Identifiable app-wide.
    private struct Capture: Identifiable {
        let id = UUID()
        let image: UIImage
    }

    @State private var selection: AppTab = .expo
    @State private var isShowingCamera = false
    @State private var pendingImage: UIImage?
    @State private var capture: Capture?

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.color1.ignoresSafeArea()

            content

            PainThinkTabBar(selection: $selection) {
                isShowingCamera = true
            }
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $isShowingCamera, onDismiss: promoteCapture) {
            CameraView(capturedImage: $pendingImage)
                .ignoresSafeArea()
        }
        .fullScreenCover(item: $capture) { capture in
            PolaroidDevelopView(image: capture.image) {
                self.capture = nil
            }
        }
    }

    // The camera sheet has to finish dismissing before the develop screen can
    // take over; presenting both at once drops the second presentation.
    private func promoteCapture() {
        guard let pendingImage else { return }
        capture = Capture(image: pendingImage)
        self.pendingImage = nil
    }

    @ViewBuilder
    private var content: some View {
        switch selection {
        case .expo:
            ExpoView(entries: SampleFeed.entries)
        case .collection:
            PlaceholderScreen(title: "Collection", note: "Polaroid dan opini kamu sendiri.")
        case .search:
            PlaceholderScreen(title: "Search", note: "Cari lukisan berdasarkan judulnya.")
        case .profile:
            PlaceholderScreen(title: "Profile", note: "Statistik, mood palette, dan museum passport.")
        }
    }
}

// Stands in for the screens that aren't built yet, so the bar can be walked end
// to end without three blank rectangles.
private struct PlaceholderScreen: View {
    let title: String
    let note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.black)

            Text(note)
                .font(.system(size: 14))
                .foregroundStyle(.black.opacity(0.45))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }
}

#Preview {
    RootView()
}
