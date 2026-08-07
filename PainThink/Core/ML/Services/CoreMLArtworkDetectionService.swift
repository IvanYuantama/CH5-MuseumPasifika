//
//  CoreMLArtworkDetectionService.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import Vision
import CoreVideo

/// GANTI PlaceholderDetectionService dengan class ini setelah model .mlpackage
/// sudah didrag ke project. Tinggal isi TODO di bawah.
final class CoreMLArtworkDetectionService: ArtworkDetectionServicing {
    private var visionModel: VNCoreMLModel?

    init() {
        // TODO: setelah model ada, uncomment & sesuaikan nama class model-nya.
        // Xcode otomatis generate class dengan nama sesuai file .mlpackage Anda.
        
         guard let model = try? YOLOv3TinyInt8LUT(configuration: MLModelConfiguration()).model,
               let vnModel = try? VNCoreMLModel(for: model) else {
             print("Gagal load model deteksi.")
             return
         }
         self.visionModel = vnModel
    }

    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void) {
        guard let visionModel else {
            completion([])
            return
        }

        let request = VNCoreMLRequest(model: visionModel) { request, error in
            if let error {
                print("Vision request error: \(error)")
            }
            guard let results = request.results as? [VNRecognizedObjectObservation] else {
                print("Hasil bukan VNRecognizedObjectObservation, dapat: \(String(describing: request.results))")
                completion([])
                return
            }
            print("Jumlah deteksi: \(results.count)")  // debug sementara

            let detections = results.map { observation -> DetectedObject in
                DetectedObject(
                    label: observation.labels.first?.identifier ?? "unknown",
                    confidence: observation.labels.first?.confidence ?? 0,
                    boundingBox: observation.boundingBox
                )
            }
            completion(detections)
        }
        request.imageCropAndScaleOption = .scaleFill

        // PENTING: kasih tahu Vision orientasi gambar yang benar.
        // Kamera portrait -> buffer aslinya landscape -> perlu rotate 90° CW -> .right
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Gagal jalankan Vision request: \(error)")
            completion([])
        }
    }
}
