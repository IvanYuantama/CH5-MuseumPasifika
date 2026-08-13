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
            CollectionView()
        case .search:
            SearchView(entries: SampleFeed.entries)
        case .profile:
            ProfileView()
        }
    }
}

// CATATAN: jangan tambahkan #Preview — Previews selalu crash di project ini
// karena JIT executor gagal me-link static lib ONNX Runtime di app target.
// Detail lengkap ada di komentar bawah PaintingDetailView.swift. Pakai Cmd+R.
