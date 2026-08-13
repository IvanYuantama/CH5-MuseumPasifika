//
//  CameraPreviewView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }

        // The preview layer doesn't follow interface rotation on its own; keep
        // its video rotation in sync so landscape shows an upright feed.
        override func layoutSubviews() {
            super.layoutSubviews()

            guard let connection = videoPreviewLayer.connection else { return }

            let orientation = window?.windowScene?.interfaceOrientation ?? .portrait
            let angle: CGFloat = switch orientation {
            case .landscapeRight: 0
            case .portraitUpsideDown: 270
            case .landscapeLeft: 180
            default: 90
            }

            if connection.isVideoRotationAngleSupported(angle) {
                connection.videoRotationAngle = angle
            }
        }
    }
}
