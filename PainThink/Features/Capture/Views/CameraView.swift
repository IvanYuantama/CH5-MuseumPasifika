import SwiftUI

struct CameraView: View {
    @State private var cameraManager = CameraManager(detectionService: CoreMLArtworkDetectionService())
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @State private var isCapturing = false
    @State private var showShutterFlash = false

    var body: some View {
        ZStack {
            Color.galleryBackground
                .ignoresSafeArea()

            if cameraManager.isSessionRunning {
                CameraPreviewView(session: cameraManager.session)
                    .ignoresSafeArea()

                // HANYA TAMPILKAN BOUNDING BOX JIKA MACHINE LEARNING (LIVE DETECTION) MENYALA
                if cameraManager.isLiveDetectionEnabled {
                    DetectionOverlayView(objects: cameraManager.detectedObjects)
                }

                VStack {
                    topBar
                    Spacer()
                    bottomControls
                }

                Color.white
                    .ignoresSafeArea()
                    .opacity(showShutterFlash ? 0.8 : 0)
                    .allowsHitTesting(false)
            } else if cameraManager.permissionDenied {
                permissionDeniedView
            } else {
                ProgressView()
                    .tint(Color.brass)
            }
        }
        .onAppear {
            cameraManager.configure()
            OrientationLock.lock(to: .portrait)
        }
        .onDisappear {
            cameraManager.stopSession()
            OrientationLock.unlock()
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.warmWhite)
                    .padding(12)
                    .background(Color.scrim, in: Circle())
            }
            Spacer()
            // Tombol ini yang mengatur isLiveDetectionEnabled
            Button { cameraManager.toggleLiveDetection() } label: {
                Image(systemName: cameraManager.isLiveDetectionEnabled ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(cameraManager.isLiveDetectionEnabled ? Color.brass : Color.warmWhite)
                    .padding(12)
                    .background(Color.scrim, in: Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var bottomControls: some View {
        HStack {
            Spacer()
            Button {
                captureAndSmartCrop()
            } label: {
                ZStack {
                    Circle().stroke(Color.brass, lineWidth: 3).frame(width: 74, height: 74)
                    Circle().fill(Color.warmWhite).frame(width: 60, height: 60)
                        .scaleEffect(isCapturing ? 0.85 : 1)
                }
            }
            .disabled(isCapturing)
            .animation(.easeOut(duration: 0.15), value: isCapturing)
            Spacer()
        }
        .padding(.bottom, 40)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill").font(.system(size: 32)).foregroundStyle(Color.brass)
            Text("Izin kamera dibutuhkan").font(.headline).foregroundStyle(Color.warmWhite)
            Text("Buka Pengaturan untuk mengizinkan akses kamera.").font(.subheadline).foregroundStyle(Color.warmWhite.opacity(0.7)).multilineTextAlignment(.center)
            Button("Buka Pengaturan") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }.buttonStyle(.borderedProminent).tint(Color.brass)
        }.padding(32)
    }

    // Fungsi Utama yang baru: Manual Capture + Smart Crop
    private func captureAndSmartCrop() {
        guard !isCapturing else { return }
        isCapturing = true
        
        // Ambil bounding box TERBARU saat user menekan tombol (jika ada)
        let currentBoundingBox = cameraManager.detectedObjects.first?.boundingBox
        
        triggerShutterEffect()

        cameraManager.capturePhoto { image in
            guard let originalImage = image else {
                finishCapture(with: nil)
                return
            }
            
            // Jika Machine Learning aktif dan ada objek terdeteksi, lakukan crop.
            // Jika tidak, foto akan disimpan full seperti kamera normal.
            if cameraManager.isLiveDetectionEnabled, let box = currentBoundingBox {
                let croppedImage = cropImage(originalImage, toRect: box)
                finishCapture(with: croppedImage)
            } else {
                finishCapture(with: originalImage)
            }
        }
    }

    private func triggerShutterEffect() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        withAnimation(.easeOut(duration: 0.08)) { showShutterFlash = true }
    }

    private func finishCapture(with finalImage: UIImage?) {
        withAnimation(.easeIn(duration: 0.2)) { showShutterFlash = false }
        capturedImage = finalImage
        dismiss()
    }

    private func cropImage(_ image: UIImage, toRect boundingBox: CGRect) -> UIImage? {
        guard let fixedImage = fixedOrientation(for: image),
              let cgImage = fixedImage.cgImage else { return nil }

        let imageWidth = fixedImage.size.width
        let imageHeight = fixedImage.size.height

        let x = boundingBox.origin.x * imageWidth
        let width = boundingBox.width * imageWidth
        let height = boundingBox.height * imageHeight
        
        // Mengkonversi kordinat Y dari CoreML/Vision (bottom-left) ke CoreGraphics (top-left)
        let y = (1 - boundingBox.origin.y - boundingBox.height) * imageHeight

        let cropRect = CGRect(x: x, y: y, width: width, height: height)

        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return image }
        
        return UIImage(cgImage: croppedCgImage, scale: fixedImage.scale, orientation: fixedImage.imageOrientation)
    }

    private func fixedOrientation(for image: UIImage) -> UIImage? {
        guard image.imageOrientation != .up else { return image }
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalizedImage
    }
}
