//
//  CaptureViewModel.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import UIKit
import Observation

@Observable
final class CaptureViewModel {
    var capturedImage: UIImage?
    var isDetecting = false
    var detectionResult: DetectPaintResponse?
    var errorMessage: String?

    var isAnalyzing = false
    var analysisResult: AnalyzeResponse?
    var analysisError: String?

    var answerText = ""

    func detectPaint() async {
        guard let image = capturedImage else { return }
        isDetecting = true
        errorMessage = nil

        do {
            let result = try await APIClient.shared.detectPaint(image: image)
            detectionResult = result
        } catch {
            errorMessage = "Gagal mendeteksi lukisan. Coba lagi ya."
        }

        isDetecting = false
    }

    func analyzePainting() async {
        guard let image = capturedImage else { return }
        isAnalyzing = true
        analysisError = nil
        analysisResult = nil

        do {
            analysisResult = try await APIClient.shared.analyzePainting(image: image)
        } catch {
            analysisError = "Gagal menganalisis lukisan. Coba lagi ya."
        }

        isAnalyzing = false
    }
}
