import Vision
import CoreVideo
import CoreImage
import CoreML

final class CoreMLArtworkDetectionService: ArtworkDetectionServicing {
    private var visionModel: VNCoreMLModel?
    private let outputName = "var_1437" // Sesuai dengan spesifikasi yolo26
    
    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly // Paksa CPU dulu untuk testing
        
        do {
            let model = try yolo26(configuration: config).model
            self.visionModel = try VNCoreMLModel(for: model)
        } catch {
            print("Gagal load model deteksi: \(error)")
        }
    }
    
    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void) {
        guard let visionModel else {
            completion([])
            return
        }
        
        let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
            guard let self else {
                completion([])
                return
            }
            
            if let error {
                print("Vision request error: \(error)")
                completion([])
                return
            }
            
            // Tangkap raw output dari var_1437
            guard let results = request.results as? [VNCoreMLFeatureValueObservation],
                  let observation = results.first(where: { $0.featureName == self.outputName }),
                  let multiArray = observation.featureValue.multiArrayValue else {
                print("Output '\(self.outputName)' tidak ditemukan. Pastikan nama output benar.")
                completion([])
                return
            }
            
            let detections = CoreMLArtworkDetectionService.parseDetections(from: multiArray)
            completion(detections)
        }
        
        // PENTING: Gunakan centerCrop agar rasio kamera (16:9) tidak rusak saat di-resize ke 416x416
        request.imageCropAndScaleOption = .centerCrop
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Gagal jalankan Vision request: \(error)")
            completion([])
        }
    }
    
    private static func parseDetections(from multiArray: MLMultiArray, confidenceThreshold: Float = 0.25) -> [DetectedObject] {
        let numDetections = multiArray.shape[1].intValue // 300
        let strides = multiArray.strides.map { $0.intValue }
        var rawDetections: [DetectedObject] = []
        
        for i in 0..<numDetections {
            func value(_ j: Int) -> Float {
                multiArray[i * strides[1] + j * strides[2]].floatValue
            }
            
            let confidence = value(4)
            guard confidence >= confidenceThreshold else { continue }
            
            // Raw value dari model (Top-Left Origin)
            let x = value(0)
            let y = value(1)
            let w = value(2)
            let h = value(3)
            let classId = Int(value(5))
            
            // 1. Normalisasi menggunakan ukuran input yolo26 yang baru (416.0)
            let normX = CGFloat(x) / 416.0
            let normW = CGFloat(w) / 416.0
            let normH = CGFloat(h) / 416.0
            
            // 2. MIMIC VNRecognizedObjectObservation (Bottom-Left Origin)
            // Karena UI kamu sebelumnya sudah berjalan sempurna dengan VNRecognizedObjectObservation,
            // UI tersebut pasti mengharapkan sumbu Y dibalik seperti ini:
            let normY = 1.0 - (CGFloat(y) / 416.0) - normH
            
            let boundingBox = CGRect(
                x: normX,
                y: normY,
                width: normW,
                height: normH
            )
            
            rawDetections.append(DetectedObject(
                label: "\(classId)", // Output class model baru
                confidence: confidence,
                boundingBox: boundingBox
            ))
        }
        
        // 3. Eksekusi NMS secara manual
        return applyNMS(to: rawDetections, iouThreshold: 0.45)
    }
    
    // MARK: - Non-Maximum Suppression (NMS)
    private static func applyNMS(to detections: [DetectedObject], iouThreshold: Float) -> [DetectedObject] {
        // Urutkan dari confidence tertinggi
        let sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var finalDetections: [DetectedObject] = []
        
        for detection in sortedDetections {
            var shouldAdd = true
            for finalDetection in finalDetections {
                let iou = calculateIoU(rectA: detection.boundingBox, rectB: finalDetection.boundingBox)
                if iou > CGFloat(iouThreshold) {
                    shouldAdd = false
                    break
                }
            }
            if shouldAdd {
                finalDetections.append(detection)
            }
        }
        return finalDetections
    }
    
    private static func calculateIoU(rectA: CGRect, rectB: CGRect) -> CGFloat {
        let intersection = rectA.intersection(rectB)
        guard !intersection.isNull else { return 0 }
        
        let intersectionArea = intersection.width * intersection.height
        let rectAArea = rectA.width * rectA.height
        let rectBArea = rectB.width * rectB.height
        
        return intersectionArea / (rectAArea + rectBArea - intersectionArea)
    }
}
