//
//  CaptureView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI

struct CaptureView: View {
    @State private var viewModel = CaptureViewModel()
    @State private var showCamera = false

    var body: some View {
        Group {
            if let image = viewModel.capturedImage {
                PolaroidDevelopView(image: image) {
                    viewModel.reset()
                }
            } else {
                VStack(spacing: 20) {
                    Button("Ambil Foto") {
                        showCamera = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(capturedImage: $viewModel.capturedImage)
                .ignoresSafeArea()
        }
    }
}
