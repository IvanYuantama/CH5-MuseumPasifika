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
    @State private var navigateToResult = false

    var body: some View {
        VStack(spacing: 20) {
            if let image = viewModel.capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(12)

                Button("Deteksi Lukisan") {
                    Task { await viewModel.detectPaint() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isDetecting)

                if viewModel.isDetecting {
                    ProgressView("Mendeteksi...")
                }

                if let result = viewModel.detectionResult {
                    Text(result.detected ? "Lukisan terdeteksi ✅" : "Tidak terdeteksi ❌")
                    Text("Confidence: \(String(format: "%.2f", result.confidence))")
                }

                if let error = viewModel.errorMessage {
                    Text(error).foregroundStyle(.red)
                }
            } else {
                Button("Ambil Foto") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .sheet(isPresented: $showCamera, onDismiss: {
            if viewModel.capturedImage != nil {
                navigateToResult = true
            }
        }) {
            CameraView(capturedImage: $viewModel.capturedImage)
                .ignoresSafeArea()
        }
        .navigationDestination(isPresented: $navigateToResult) {
            DragAndDropView(paintingImage: viewModel.capturedImage)
        }
    }
}
