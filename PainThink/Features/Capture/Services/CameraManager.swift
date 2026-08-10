//
//  CameraManager.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import AVFoundation
import UIKit
import Vision
import Observation

@Observable
final class CameraManager: NSObject {
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoQueue = DispatchQueue(label: "camera.video.queue")

    private let detectionService: ArtworkDetectionServicing
    private var lastDetectionTime = Date.distantPast
    private let detectionInterval: TimeInterval = 0.2

    var detectedObjects: [DetectedObject] = []
    var isSessionRunning = false
    var permissionDenied = false
    var isLiveDetectionEnabled = true


    private var photoCaptureCompletion: ((UIImage?) -> Void)?

    init(detectionService: ArtworkDetectionServicing = PlaceholderDetectionService()) {
        self.detectionService = detectionService
        super.init()
    }

    func configure() {
        checkPermission { [weak self] granted in
            guard granted else {
                self?.permissionDenied = true
                return
            }
            self?.setupSession()
        }
    }

    private func checkPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        default:
            completion(false)
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .inputPriority

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        videoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        if session.canAddOutput(videoDataOutput) {
            session.addOutput(videoDataOutput)
        }

        configureFrameRate(for: camera, targetFPS: 60)

        session.commitConfiguration()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                self?.isSessionRunning = true
            }
        }
    }

    private func configureFrameRate(for device: AVCaptureDevice, targetFPS: Double) {
        let candidates = device.formats.filter { format in
            format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= targetFPS }
        }
        guard let bestFormat = candidates.max(by: { lhs, rhs in
            let l = CMVideoFormatDescriptionGetDimensions(lhs.formatDescription)
            let r = CMVideoFormatDescriptionGetDimensions(rhs.formatDescription)
            return (l.width * l.height) < (r.width * r.height)
        }) else { return }

        do {
            try device.lockForConfiguration()
            device.activeFormat = bestFormat
            device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFPS))
            device.activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(targetFPS))
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            device.unlockForConfiguration()
        } catch {
            print("Gagal set frame rate: \(error)")
        }
    }

    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCaptureCompletion = completion
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    func stopSession() {
        session.stopRunning()
    }
    
    func toggleLiveDetection() {
            isLiveDetectionEnabled.toggle()
            if !isLiveDetectionEnabled {
                // Bersihkan overlay lama begitu dimatikan, biar tidak nyangkut di layar
                detectedObjects = []
            }
        }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard isLiveDetectionEnabled else { return }  // <-- gate di sini

        let now = Date()
        guard now.timeIntervalSince(lastDetectionTime) >= detectionInterval else { return }
        lastDetectionTime = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        detectionService.detect(in: pixelBuffer) { [weak self] objects in
            DispatchQueue.main.async {
                self?.detectedObjects = objects
            }
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCaptureCompletion?(nil)
            return
        }
        photoCaptureCompletion?(image)
    }
}
