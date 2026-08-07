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

                // Biarkan ini ada agar pengguna tahu objek sudah terdeteksi dan di mana letak crop-nya nanti
                DetectionOverlayView(objects: cameraManager.detectedObjects)

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
        // HAPUS blok .onChange(...) di sini karena kita tidak ingin auto-capture lagi
    }

    private var topBar: some View {
        // ... (Isi topBar sama persis seperti sebelumnya) ...
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.warmWhite)
                    .padding(12)
                    .background(Color.scrim, in: Circle())
            }
            Spacer()
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
        // ... (Isi bottomControls sama persis seperti sebelumnya) ...
        HStack {
            Spacer()
            Button {
                captureAndSmartCrop() // Panggil fungsi baru di sini
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
        // ... (Sama persis seperti sebelumnya) ...
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
            
            // Jika ada objek yang terdeteksi saat tombol ditekan, crop!
            // Jika tidak ada, kembalikan gambar asli (fallback).
            if let box = currentBoundingBox, cameraManager.isLiveDetectionEnabled {
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

    // 1. Ganti fungsi cropImage sebelumnya dengan ini:
        private func cropImage(_ image: UIImage, toRect boundingBox: CGRect) -> UIImage? {
            // A. Perbaiki orientasi gambar mentah terlebih dahulu
            guard let fixedImage = fixedOrientation(for: image),
                  let cgImage = fixedImage.cgImage else { return nil }

            // B. Gunakan ukuran dari gambar yang sudah diperbaiki (bukan cgImage mentah)
            let imageWidth = fixedImage.size.width
            let imageHeight = fixedImage.size.height

            let x = boundingBox.origin.x * imageWidth
            let width = boundingBox.width * imageWidth
            let height = boundingBox.height * imageHeight
            
            // C. Balik koordinat Y karena Vision (CoreML) menggunakan titik nol di Bawah-Kiri
            let y = (1 - boundingBox.origin.y - boundingBox.height) * imageHeight

            let cropRect = CGRect(x: x, y: y, width: width, height: height)

            // D. Potong gambar
            guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return image }
            
            // E. Kembalikan gambar hasil potongan
            return UIImage(cgImage: croppedCgImage, scale: fixedImage.scale, orientation: fixedImage.imageOrientation)
        }

        // 2. Tambahkan fungsi utilitas ini di dalam CameraView (di bawah cropImage)
        // Fungsi ini memaksa piksel gambar ditulis ulang agar posisinya benar (tegak lurus)
        private func fixedOrientation(for image: UIImage) -> UIImage? {
            guard image.imageOrientation != .up else { return image }
            
            UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
            image.draw(in: CGRect(origin: .zero, size: image.size))
            let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return normalizedImage
        }
}
