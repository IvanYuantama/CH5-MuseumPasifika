//
//  ContentView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI
import PhotosUI
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct ContentView: View {
    // Model runner (the actual inference lives in Qwen25VLModel.swift).
    private let model = Qwen25VLModel()

    // Image input
    @State private var photoItem: PhotosPickerItem?
    @State private var displayImage: Image?
    @State private var cgImage: CGImage?

    // Text input
    @State private var prompt: String = ""

    // Output / status
    @State private var response: String = ""
    @State private var isRunning = false
    @State private var errorMessage: String?

    private var canRun: Bool {
        cgImage != nil && !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isRunning
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    imageSection
                    promptSection
                    runButton
                    outputSection
                }
                .padding()
            }
            .navigationTitle("Qwen2.5-VL")
        }
        .onChange(of: photoItem) { _, newItem in
            Task { await loadImage(from: newItem) }
        }
    }

    // MARK: - Image input

    private var imageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image").font(.headline)

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .frame(height: 220)

                if let displayImage {
                    displayImage
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("No image selected")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                Label(displayImage == nil ? "Select Image" : "Change Image",
                      systemImage: "photo")
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Text input

    private var promptSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Prompt").font(.headline)
            TextField("Ask something about the image…", text: $prompt, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Run

    private var runButton: some View {
        Button(action: run) {
            HStack {
                if isRunning { ProgressView().controlSize(.small) }
                Text(isRunning ? "Running…" : "Run")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!canRun)
    }

    // MARK: - Output

    @ViewBuilder
    private var outputSection: some View {
        if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(.red)
                .font(.callout)
        }

        if !response.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Response").font(.headline)
                Text(response)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Actions

    private func loadImage(from item: PhotosPickerItem?) async {
        errorMessage = nil
        guard let item else {
            displayImage = nil
            cgImage = nil
            return
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                errorMessage = "Could not read the selected image."
                return
            }
            cgImage = image
            displayImage = Image(decorative: image, scale: 1)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func run() {
        guard let cgImage else { return }
        let promptText = prompt
        isRunning = true
        errorMessage = nil
        response = ""

        Task {
            do {
                let result = try await model.generate(image: cgImage, prompt: promptText)
                response = result
            } catch {
                errorMessage = error.localizedDescription
            }
            isRunning = false
        }
    }
}

#Preview {
    ContentView()
}
