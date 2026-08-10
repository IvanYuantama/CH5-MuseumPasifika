//
//  CaptureView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI

struct CaptureView: View {
    @State private var viewModel = CaptureViewModel()
    @State private var speechRecognizer = SpeechRecognizer()
    @State private var showCamera = false

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

                if viewModel.isAnalyzing {
                    ProgressView("Menganalisis...")
                }

                if let analysis = viewModel.analysisResult {
                    Text(analysis.openingQuestion).font(.subheadline).italic()

                    answerInput
                }

                if let analysisError = viewModel.analysisError {
                    Text(analysisError).foregroundStyle(.red)
                }
            } else {
                Button("Ambil Foto") {
                    showCamera = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .sheet(isPresented: $showCamera) {
            CameraView(capturedImage: $viewModel.capturedImage)
                .ignoresSafeArea()
        }
        .onChange(of: viewModel.capturedImage) { _, newImage in
            guard newImage != nil else { return }
            Task { await viewModel.analyzePainting() }
        }
        .onChange(of: speechRecognizer.transcript) { _, newTranscript in
            viewModel.answerText = newTranscript
        }
    }

    private var answerInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextEditor(text: $viewModel.answerText)
                .frame(minHeight: 100)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            HStack {
                Button {
                    toggleRecording()
                } label: {
                    Label(
                        speechRecognizer.isRecording ? "Berhenti" : "Rekam Suara",
                        systemImage: speechRecognizer.isRecording ? "stop.circle.fill" : "mic.circle.fill"
                    )
                }
                .buttonStyle(.bordered)
                .tint(speechRecognizer.isRecording ? .red : .accentColor)

                if let error = speechRecognizer.errorMessage {
                    Text(error).font(.caption).foregroundStyle(.red)
                }
            }
        }
    }

    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopTranscribing()
        } else {
            speechRecognizer.transcript = viewModel.answerText
            speechRecognizer.startTranscribing()
        }
    }
}
