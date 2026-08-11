import Vision
import CoreVideo
import CoreML

final class CoreMLArtworkDetectionService: ArtworkDetectionServicing {
    private var visionModel: VNCoreMLModel?

    init() {
        let config = MLModelConfiguration()
        config.computeUnits = .cpuOnly

        do {
            let model = try PaintingDetector_2(configuration: config).model
            self.visionModel = try VNCoreMLModel(for: model)
        } catch {
            print("Failed to load detection model: \(error)")
        }
    }

    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void) {
        guard let visionModel else {
            completion([])
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error {
                print("Vision request error: \(error)")
                completion([])
                return
            }

            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                completion([])
                return
            }

            let detections = results.map { observation in
                DetectedObject(
                    label: observation.labels.first?.identifier ?? "unknown",
                    confidence: observation.labels.first?.confidence ?? observation.confidence,
                    boundingBox: observation.boundingBox
                )
            }

            completion(detections)
        }

        // Match CreateML's training scale mode so coordinates are accurate
        request.imageCropAndScaleOption = .scaleFill

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform Vision request: \(error)")
            completion([])
        }
    }
}
