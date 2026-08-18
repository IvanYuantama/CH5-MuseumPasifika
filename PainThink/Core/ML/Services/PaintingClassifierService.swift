//
//  PaintingClassifierService.swift
//  PainThink
//

import UIKit
import Vision
import CoreML

enum PaintingClassifierError: Error {
    case modelUnavailable
    case noResult
}

final class PaintingClassifierService {

    private let model: VNCoreMLModel?

    init() {
        guard let modelURL = Bundle.main.url(forResource: "MuseumPaintng2", withExtension: "mlmodelc") else {
            print("File MuseumPaintng2.mlmodelc tidak ditemukan di Bundle.")
            self.model = nil
            return
        }

        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            let mlModel = try MLModel(contentsOf: modelURL, configuration: configuration)
            self.model = try VNCoreMLModel(for: mlModel)
        } catch {
            print("Gagal load model MuseumPaintng2: \(error)")
            self.model = nil
        }
    }

    func classify(_ image: UIImage) async throws -> (label: String, confidence: Double) {
        guard let model, let cgImage = image.cgImage else {
            throw PaintingClassifierError.modelUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: model) { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let topResult = (request.results as? [VNClassificationObservation])?.first else {
                    continuation.resume(throwing: PaintingClassifierError.noResult)
                    return
                }

                continuation.resume(returning: (topResult.identifier, Double(topResult.confidence)))
            }
            request.imageCropAndScaleOption = .centerCrop

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: image.cgImageOrientation)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}
