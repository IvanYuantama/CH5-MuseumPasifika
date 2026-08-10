//
//  CoreMLArtworkDetectionService.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import UIKit
import CoreVideo
import OnnxRuntimeBindings

final class CoreMLArtworkDetectionService: ArtworkDetectionServicing {
    
    private var ortSession: ORTSession?
    private var ortEnv: ORTEnv?
    private let inputSize: CGFloat = 416
    private let confidenceThreshold: Float = 0.25
    private let iouThreshold: Float = 0.45
    private let paintingClassId: Int = 0

    init() {
        // 1. Load file 'yolo26.onnx' dari Bundle project
        guard let modelPath = Bundle.main.path(forResource: "yolo26amadeus", ofType: "onnx") else {
            print("❌ File yolo26.onnx tidak ditemukan di Bundle.")
            return
        }

        do {
            self.ortEnv = try ORTEnv(loggingLevel: .warning)
            self.ortSession = try ORTSession(env: ortEnv!, modelPath: modelPath, sessionOptions: nil)
            print("✅ ONNX Session berhasil diinisialisasi di Service.")
        } catch {
            print("❌ Gagal load model ONNX: \(error)")
        }
    }

    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void) {
        guard let session = ortSession else {
            completion([])
            return
        }

        // 2. Konversi CVPixelBuffer ke UIImage & sesuaikan rotasi kamera
        guard let uiImage = UIImage(pixelBuffer: pixelBuffer)?.rotate(radians: .pi / 2) else {
            completion([])
            return
        }

        // 3. Resize ke 640x640 sesuai input model YOLO
        guard let resizedImage = uiImage.resize(to: CGSize(width: inputSize, height: inputSize)) else {
            completion([])
            return
        }

        let pixelValues = resizedImage.toRGBFloatArray()
        guard !pixelValues.isEmpty else {
            completion([])
            return
        }

        do {
            // 4. Siapkan Tensor Input
            let inputData = NSMutableData(bytes: pixelValues, length: pixelValues.count * MemoryLayout<Float>.size)
            let inputShape: [NSNumber] = [1, 3, NSNumber(value: Int(inputSize)), NSNumber(value: Int(inputSize))]
            let inputTensor = try ORTValue(tensorData: inputData, elementType: .float, shape: inputShape)

            let inputName = "images"
            let outputName = "output0"

            // 5. Jalankan Inference ONNX
            let outputs = try session.run(
                withInputs: [inputName: inputTensor],
                outputNames: [outputName],
                runOptions: nil
            )

            guard let outputValue = outputs[outputName] else {
                completion([])
                return
            }

            let shapeInfo = try outputValue.tensorTypeAndShapeInfo()
            let shape = shapeInfo.shape.map { $0.intValue }

            let outputData = try outputValue.tensorData() as Data
            let floatCount = outputData.count / MemoryLayout<Float>.size
            let outputArray = outputData.withUnsafeBytes { rawBuffer -> [Float] in
                Array(rawBuffer.bindMemory(to: Float.self).prefix(floatCount))
            }

            // 6. Parsing Output menggunakan Smart Parser (Otomatis & Presisi)
            let detections = parseSmartYoloOutput(
                outputArray,
                shape: shape,
                confidenceThreshold: confidenceThreshold,
                inputSize: inputSize,
                originalSize: uiImage.size
            )

            // 7. Mapping ke DetectedObject milik PainThink (Normalisasi 0.0 - 1.0)
            let mappedObjects = detections.map { d -> DetectedObject in
                let normRect = CGRect(
                    x: d.boundingBox.origin.x / uiImage.size.width,
                    y: d.boundingBox.origin.y / uiImage.size.height,
                    width: d.boundingBox.width / uiImage.size.width,
                    height: d.boundingBox.height / uiImage.size.height
                )
                
                // Gunakan label "Painting" atau ID string sesuai preferensi aplikasi Anda
                return DetectedObject(
                    label: "Painting",
                    confidence: d.confidence,
                    boundingBox: normRect
                )
            }

            completion(mappedObjects)

        } catch {
            print("❌ Error inference ONNX di service: \(error)")
            completion([])
        }
    }

    // MARK: - Smart YOLO Parser (Otomatis deteksi format output)
    private func parseSmartYoloOutput(
        _ data: [Float],
        shape: [Int],
        confidenceThreshold: Float,
        inputSize: CGFloat,
        originalSize: CGSize
    ) -> [ObjectDetectionInternal] {
        guard shape.count == 3 else {
            print("⚠️ Shape output tidak valid: \(shape)")
            return []
        }
        
        let dim1 = shape[1]
        let dim2 = shape[2]
        
        var rawDetections: [ObjectDetectionInternal] = []
        let scaleX = originalSize.width / inputSize
        let scaleY = originalSize.height / inputSize

        // 1. Format End-to-End YOLO (Contoh: [1, 300, 6])
        if dim1 > dim2 {
            let numDetections = dim1
            let attributes = dim2
            
            for i in 0..<numDetections {
                let baseIndex = i * attributes
                if baseIndex + 5 >= data.count { break }
                
                let confidence = data[baseIndex + 4]
                let classId = Int(data[baseIndex + 5])
                
                guard confidence >= confidenceThreshold, classId == paintingClassId else { continue }
                
                let xmin = CGFloat(data[baseIndex + 0])
                let ymin = CGFloat(data[baseIndex + 1])
                let xmax = CGFloat(data[baseIndex + 2])
                let ymax = CGFloat(data[baseIndex + 3])
                
                let box = CGRect(
                    x: xmin * scaleX,
                    y: ymin * scaleY,
                    width: (xmax - xmin) * scaleX,
                    height: (ymax - ymin) * scaleY
                )
                rawDetections.append(ObjectDetectionInternal(classId: classId, confidence: confidence, boundingBox: box))
            }
            return rawDetections // Format ini tidak butuh NMS
            
        } else {
            // 2. Format Standar YOLOv8/v11 (Contoh: [1, 6, 8400] atau [1, 84, 8400])
            let numAttributes = dim1
            let numAnchors = dim2
            let numClasses = numAttributes - 4
            
            for anchor in 0..<numAnchors {
                var bestClassId = 0
                var bestScore: Float = 0
                
                for c in 0..<numClasses {
                    let score = data[(4 + c) * numAnchors + anchor]
                    if score > bestScore {
                        bestScore = score
                        bestClassId = c
                    }
                }
                
                guard bestScore >= confidenceThreshold, bestClassId == paintingClassId else { continue }
                
                let cx = CGFloat(data[0 * numAnchors + anchor])
                let cy = CGFloat(data[1 * numAnchors + anchor])
                let w  = CGFloat(data[2 * numAnchors + anchor])
                let h  = CGFloat(data[3 * numAnchors + anchor])
                
                let box = CGRect(
                    x: (cx - w / 2) * scaleX,
                    y: (cy - h / 2) * scaleY,
                    width: w * scaleX,
                    height: h * scaleY
                )
                rawDetections.append(ObjectDetectionInternal(classId: bestClassId, confidence: bestScore, boundingBox: box))
            }
            
            return nonMaxSuppression(rawDetections, iouThreshold: iouThreshold)
        }
    }

    // MARK: - Helper NMS (Non-Max Suppression)
    private func nonMaxSuppression(_ detections: [ObjectDetectionInternal], iouThreshold: Float) -> [ObjectDetectionInternal] {
        let grouped = Dictionary(grouping: detections, by: { $0.classId })
        var result: [ObjectDetectionInternal] = []

        for (_, group) in grouped {
            let sorted = group.sorted { $0.confidence > $1.confidence }
            var kept: [ObjectDetectionInternal] = []

            for candidate in sorted {
                let overlapsExisting = kept.contains { existing in
                    iou(candidate.boundingBox, existing.boundingBox) > iouThreshold
                }
                if !overlapsExisting {
                    kept.append(candidate)
                }
            }
            result.append(contentsOf: kept)
        }
        return result
    }

    private func iou(_ a: CGRect, _ b: CGRect) -> Float {
        let intersection = a.intersection(b)
        guard !intersection.isNull, intersection.width > 0, intersection.height > 0 else { return 0 }
        let intersectionArea = intersection.width * intersection.height
        let unionArea = (a.width * a.height) + (b.width * b.height) - intersectionArea
        guard unionArea > 0 else { return 0 }
        return Float(intersectionArea / unionArea)
    }
}

// Struktur internal untuk parsing
private struct ObjectDetectionInternal {
    let classId: Int
    let confidence: Float
    let boundingBox: CGRect
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

    func toRGBFloatArray() -> [Float] {
        guard let cgImage = self.cgImage else { return [] }
        let width = cgImage.width
        let height = cgImage.height
        let pixelCount = width * height

        var rawBytes = [UInt8](repeating: 0, count: pixelCount * 4)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &rawBytes,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return []
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var rChannel = [Float](repeating: 0, count: pixelCount)
        var gChannel = [Float](repeating: 0, count: pixelCount)
        var bChannel = [Float](repeating: 0, count: pixelCount)

        for i in 0..<pixelCount {
            let offset = i * 4
            rChannel[i] = Float(rawBytes[offset]) / 255.0
            gChannel[i] = Float(rawBytes[offset + 1]) / 255.0
            bChannel[i] = Float(rawBytes[offset + 2]) / 255.0
        }

        return rChannel + gChannel + bChannel
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
