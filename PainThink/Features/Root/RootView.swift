//
//  RootView.swift
//  PainThink
//

import SwiftUI

// Linear navigation flow:
//   FindYourPainting (once) → CameraView → PolaroidDevelopView → PhotoDevelopedView → CollectionView → CameraView
struct RootView: View {

    enum Screen: Equatable {
        case welcome
        case camera
        case develop(UIImage)
        case collection

        static func == (lhs: Screen, rhs: Screen) -> Bool {
            switch (lhs, rhs) {
            case (.welcome, .welcome), (.camera, .camera), (.collection, .collection): return true
            case (.develop, .develop): return true
            default: return false
            }
        }
    }

    @State private var screen: Screen = .welcome
    @State private var pendingImage: UIImage?

    var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            contentView
        }
        .onAppear {
            OrientationLock.enforcePortrait()
        }
        .animation(.easeInOut(duration: 0.35), value: screenKey)
    }

    @ViewBuilder
    private var contentView: some View {
        switch screen {
        case .welcome:
            FindYourPaintingView {
                withAnimation(.easeInOut(duration: 0.4)) {
                    screen = .camera
                }
            }
            .transition(.opacity)

        case .camera:
            CameraView(capturedImage: $pendingImage) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    screen = .collection
                }
            }
            .ignoresSafeArea()
                .onChange(of: pendingImage) { _, newImage in
                    guard let img = newImage else { return }
                    pendingImage = nil
                    withAnimation(.easeInOut(duration: 0.35)) {
                        screen = .develop(img)
                    }
                }

        case .develop(let image):
            PolaroidDevelopView(
                image: image,
                onGoToCollection: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        screen = .collection
                    }
                },
                onGoToCamera: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        screen = .camera
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))

        case .collection:
            CollectionView(onCameraTap: {
                withAnimation(.easeInOut(duration: 0.35)) {
                    screen = .camera
                }
            })
            .transition(.asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            ))
        }
    }

    private var screenKey: String {
        switch screen {
        case .welcome:    return "welcome"
        case .camera:     return "camera"
        case .develop:    return "develop"
        case .collection: return "collection"
        }
    }
}

// CATATAN: jangan tambahkan #Preview — Previews selalu crash di project ini
// karena JIT executor gagal me-link static lib ONNX Runtime di app target.
// Detail lengkap ada di komentar bawah PaintingDetailView.swift. Pakai Cmd+R.
