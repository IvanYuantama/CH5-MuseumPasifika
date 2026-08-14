//
//  CoreMLArtworkDetectionService.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//


import UIKit
import CoreVideo
import CoreML
import CoreImage

final class CoreMLArtworkDetectionService: ArtworkDetectionServicing {

    private var model: MLModel?
    private let inputSize: CGFloat = 640
    private let confidenceThreshold: Double = 0.25
    private let iouThreshold: Double = 0.7
    private let paintingClassId: Int = 0

    private let ciContext = CIContext()

    init() {
        guard let modelURL = Bundle.main.url(forResource: "yolov8test", withExtension: "mlmodelc") else {
            print("File yolov8test.mlmodelc tidak ditemukan di Bundle.")
            return
        }

        do {
            let configuration = MLModelConfiguration()
            configuration.computeUnits = .all
            self.model = try MLModel(contentsOf: modelURL, configuration: configuration)
            print("Core ML model berhasil diinisialisasi di Service.")
        } catch {
            print("Gagal load model Core ML: \(error)")
        }
    }

    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void) {
        guard let model = model else {
            completion([])
            return
        }

        guard let uiImage = UIImage(pixelBuffer: pixelBuffer)?.rotate(radians: .pi / 2) else {
            completion([])
            return
        }

        guard let resizedImage = uiImage.resize(to: CGSize(width: inputSize, height: inputSize)),
              let inputPixelBuffer = resizedImage.toCVPixelBuffer(size: CGSize(width: inputSize, height: inputSize)) else {
            completion([])
            return
        }

        do {
            let inputFeatures: [String: MLFeatureValue] = [
                "image": MLFeatureValue(pixelBuffer: inputPixelBuffer),
                "iouThreshold": MLFeatureValue(double: iouThreshold),
                "confidenceThreshold": MLFeatureValue(double: confidenceThreshold)
            ]
            let provider = try MLDictionaryFeatureProvider(dictionary: inputFeatures)

            let output = try model.prediction(from: provider)

            guard let confidenceArray = output.featureValue(for: "confidence")?.multiArrayValue,
                  let coordinatesArray = output.featureValue(for: "coordinates")?.multiArrayValue else {
                completion([])
                return
            }

            let detectedObjects = parseCoreMLOutput(
                confidence: confidenceArray,
                coordinates: coordinatesArray
            )

            completion(detectedObjects)

        } catch {
            print("Error inference Core ML di service: \(error)")
            completion([])
        }
    }

    // MARK: - Parsing Output Core ML (confidence + coordinates, NMS sudah dilakukan model)
    private func parseCoreMLOutput(
        confidence: MLMultiArray,
        coordinates: MLMultiArray
    ) -> [DetectedObject] {
        let numBoxes = confidence.shape[0].intValue
        let numClasses = confidence.shape[1].intValue

        guard numBoxes > 0, coordinates.shape[0].intValue == numBoxes, coordinates.shape[1].intValue == 4 else {
            return []
        }

        var results: [DetectedObject] = []

        for boxIndex in 0..<numBoxes {
            var bestClassId = 0
            var bestScore: Float = 0

            for classIndex in 0..<numClasses {
                let score = confidence[[boxIndex, classIndex] as [NSNumber]].floatValue
                if score > bestScore {
                    bestScore = score
                    bestClassId = classIndex
                }
            }

            guard bestScore >= Float(confidenceThreshold), bestClassId == paintingClassId else { continue }

            // MARK: Konversi coordinates -> CGRect
            let cx = CGFloat(coordinates[[boxIndex, 0] as [NSNumber]].floatValue)
            let cy = CGFloat(coordinates[[boxIndex, 1] as [NSNumber]].floatValue)
            let w  = CGFloat(coordinates[[boxIndex, 2] as [NSNumber]].floatValue)
            let h  = CGFloat(coordinates[[boxIndex, 3] as [NSNumber]].floatValue)

            let normRect = CGRect(
                x: cx - w / 2,
                y: cy - h / 2,
                width: w,
                height: h
            )

            results.append(
                DetectedObject(
                    label: "Painting",
                    confidence: bestScore,
                    boundingBox: normRect
                )
            )
        }

        return results
    }
}

// MARK: - Helper Ekstensi UIImage & CVPixelBuffer
extension UIImage {
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        self.init(cgImage: cgImage)
    }

    func resize(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: size))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }

    func toCVPixelBuffer(size: CGSize) -> CVPixelBuffer? {
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]

        var pixelBufferOut: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32BGRA,
            attrs as CFDictionary,
            &pixelBufferOut
        )

        guard status == kCVReturnSuccess, let pixelBuffer = pixelBufferOut else { return nil }

        CVPixelBufferLockBaseAddress(pixelBuffer, [])
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, []) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(pixelBuffer),
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ), let cgImage = self.cgImage else {
            return nil
        }

        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        return pixelBuffer
    }

    func rotate(radians: CGFloat) -> UIImage? {
        let cgImage = self.cgImage
        let sinValue = abs(sin(radians))
        let cosValue = abs(cos(radians))
        let newSize = CGSize(
            width: self.size.height * sinValue + self.size.width * cosValue,
            height: self.size.height * cosValue + self.size.width * sinValue
        )
        let colorSpace = cgImage?.colorSpace ?? CGColorSpaceCreateDeviceRGB()

        guard let context = CGContext(
            data: nil,
            width: Int(newSize.width),
            height: Int(newSize.height),
            bitsPerComponent: cgImage?.bitsPerComponent ?? 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage?.bitmapInfo.rawValue ?? CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.translateBy(x: newSize.width / 2, y: newSize.height / 2)
        context.rotate(by: radians)
        context.scaleBy(x: 1.0, y: -1.0)
        context.draw(cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        guard let rotatedCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: rotatedCGImage)
    }
}
