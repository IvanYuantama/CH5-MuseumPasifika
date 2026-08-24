import SwiftUI

// Redesigned capture screen: full-bleed viewfinder fills top portion,
// corner-bracket overlay in yellow, circular shutter button below,
// small polaroid stack thumbnail at bottom left.
struct CameraView: View {
    @State private var cameraManager = CameraManager(detectionService: CoreMLArtworkDetectionService())
    @Binding var capturedImage: UIImage?
    var onGoToCollection: (() -> Void)? = nil
    
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @State private var isCapturing = false
    @State private var showShutterFlash = false
    @State private var countdown: Int?
    @State private var lastDragAngle: Double? = nil
    @State private var viewfinderSize: CGSize = .zero
    
    private var isLandscape: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()
            
            if cameraManager.permissionDenied {
                CameraPermissionDeniedView(onNotNow: { onGoToCollection?() })
            } else if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }
        }
        .onAppear { cameraManager.configure() }
        .onDisappear { cameraManager.stopSession() }
    }
    
    // MARK: - Layouts
    
    private var portraitLayout: some View {
            VStack(spacing: 0) {
                // Viewfinder dengan ukuran dan padding spesifik
                viewfinderCard
                    .frame(width: 339, height: 412) // Mengatur lebar 339 dan tinggi 412
                    .padding(.horizontal, 27)       // Padding kiri dan kanan 27
                    .padding(.top, 103)             // Padding atas 103
                
                Spacer()
                
                // Bottom controls: shutter ring above, polaroid stub below
                VStack(spacing: 18) {
                    // Perfectly centered shutter ring
                    shutterButton
                        .frame(width: 96, height: 96)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 2, y: 3)
                    
                    HStack {
                        polaroidStub
                            .padding(.leading, 40)
                        Spacer()
                    }
                }
                .padding(.bottom, 52)
            }
        }
    
    private var landscapeLayout: some View {
        HStack(spacing: 24) {
            viewfinderCard
                .padding(.leading, 24)
                .padding(.vertical, 20)
            
            VStack {
                Spacer()
                shutterButton
                    .frame(width: 80, height: 80)
                Spacer()
            }
            .padding(.trailing, 36)
        }
    }
    
    // MARK: - Viewfinder with corner brackets
    
    private var viewfinderCard: some View {
            ZStack {
                // Camera feed or black placeholder
                Group {
                    if cameraManager.isSessionRunning {
                        CameraPreviewView(session: cameraManager.session)
                    } else {
                        Color.black
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(10)
                
                // Bounding box sengaja gak digambar — deteksinya tetap jalan
                // karena hasilnya dipakai buat crop foto ke area lukisan
                // (lihat currentBoundingBox di bawah).
                DetectionOverlayView(objects: cameraManager.detectedObjects)
                    .clipShape(RoundedRectangle(cornerRadius: 12).inset(by: 10))

                // Countdown
                if let countdown {
                    Text("\(countdown)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))
                        .contentTransition(.numericText(countsDown: true))
                }
                
                // Shutter flash
                Color.white
                    .opacity(showShutterFlash ? 0.8 : 0)
                    .allowsHitTesting(false)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(10)
                
                // Corner brackets drawn on top
                CornerBracketsView()
            }
            // PERHATIAN: .aspectRatio telah dihapus agar mengikuti frame 339x412 dari portraitLayout
            .animation(.easeInOut(duration: 0.2), value: countdown)
            .background(
                GeometryReader { geo in
                    Color.clear
                        .onAppear { viewfinderSize = geo.size }
                        .onChange(of: geo.size) { _, newValue in viewfinderSize = newValue }
                }
            )
        }
    
    // MARK: - Shutter button (ring style)
    
    @State private var shutterRotation: Double = 0

    // Muncul tiap kali layar kamera dibuka, hilang begitu ring-nya diputer —
    // jadi gak numpuk di layar pas user lagi ngebidik.
    @State private var showsZoomHint = true

    private var shutterButton: some View {
            ZStack {
                // Inner white circle (Shutter)
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .onTapGesture(perform: shutterTapped)
                    .accessibilityLabel("Shutter — tap to capture")
                
                // Outer ring (yellow with 8 tick marks) acting as zoom knob
                ZStack {
                    Circle()
                        .stroke(Color.color3, lineWidth: 8)
                        .frame(width: 76, height: 76)
                    
                    // 8 tick marks around the ring
                    ForEach(0..<8) { i in
                        let angle = Double(i) / 8.0 * .pi * 2
                        let isMainTick = i % 2 == 0
                        
                        Rectangle()
                            .fill(Color.gray.opacity(0.7))
                            .frame(width: 2, height: isMainTick ? 8 : 4)
                            .offset(y: isMainTick ? -38 : -36)
                            .rotationEffect(.radians(angle))
                    }
                }
                .rotationEffect(.degrees(shutterRotation))
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let center = CGPoint(x: 40, y: 40)
                            let vector = CGVector(dx: value.location.x - center.x, dy: value.location.y - center.y)
                            let angle = atan2(vector.dy, vector.dx)
                            let degrees = angle * 180 / .pi
                            
                            if let last = lastDragAngle {
                                // Hitung perubahan sudut (delta)
                                var delta = degrees - last
                                
                                // Tangani lonjakan sudut ketika melewati batas -180 dan 180
                                if delta > 180 { delta -= 360 }
                                else if delta < -180 { delta += 360 }
                                
                                // Tambahkan delta ke total rotasi saat ini
                                shutterRotation += delta
                                
                                // LIMIT MIN DAN MAX ROTASI DI SINI
                                let maxRotation: Double = 270 // Maksimal putaran 270 derajat (3/4 lingkaran)
                                shutterRotation = max(0, min(shutterRotation, maxRotation))
                                
                                // Convert rotation to zoom (1x to 5x)
                                let zoomFactor = Float(1 + (shutterRotation / maxRotation) * 4)
                                cameraManager.setZoom(zoomFactor)
                            }
                            
                            // Simpan sudut saat ini untuk kalkulasi berikutnya
                            lastDragAngle = degrees
                        }
                        .onEnded { _ in
                            // Reset drag angle saat sentuhan dilepas
                            lastDragAngle = nil
                            // Ring-nya udah ketemu sendiri — petunjuk gak perlu lagi.
                            withAnimation(.easeOut(duration: 0.25)) {
                                showsZoomHint = false
                            }
                        }
                )
            }
            .frame(width: 80, height: 80)
            .scaleEffect(isCapturing ? 0.92 : 1)
            .opacity(hasHighConfidenceDetection ? 1 : 0.4)
            .animation(.easeOut(duration: 0.12), value: isCapturing)
            .animation(.easeInOut(duration: 0.2), value: hasHighConfidenceDetection)
            .overlay(alignment: .top) {
                if showsZoomHint {
                    ZoomHintCallout()
                        .fixedSize()
                        .offset(y: -48)
                        .transition(.opacity.combined(with: .scale(scale: 0.92)))
                }
            }
            .onAppear { showsZoomHint = true }   // tiap masuk kamera, muncul lagi
        }
    
    // MARK: - Polaroid stub (bottom left)
    
    private var polaroidStub: some View {
        ZStack {
            // Shadow card behind
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.gray.opacity(0.3)) // Warna abu-abu untuk tumpukan belakang
                .frame(width: 32, height: 42)
                .rotationEffect(.degrees(25)) // Rotasi agar terlihat miring
                .offset(x: 10, y: 5) // Geser ke kanan bawah
            
            // Front polaroid
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.color3) // Warna kuning
                .frame(width: 32, height: 42)
        }
        .accessibilityHidden(true)
        .onTapGesture {
            onGoToCollection?()
        }
    }
    
    // MARK: - Capture logic
    
    private var hasHighConfidenceDetection: Bool {
        cameraManager.detectedObjects.contains { $0.confidence >= 0.80 && isFullyInPreview($0.boundingBox) }
    }

    // Returns true if the normalized bounding box is entirely within the visible
    // camera preview area, accounting for aspect-fill cropping.
    private func isFullyInPreview(_ box: CGRect) -> Bool {
        guard viewfinderSize != .zero else { return false }
        // Subtract the 10pt padding on all sides to match the actual preview area
        let size = CGSize(width: viewfinderSize.width - 20, height: viewfinderSize.height - 20)
        guard size.width > 0, size.height > 0 else { return false }

        let isLandscapePreview = size.width > size.height
        let imageAspectRatio: CGFloat = isLandscapePreview ? (16.0 / 9.0) : (9.0 / 16.0)
        let viewAspectRatio = size.width / size.height

        let scaledWidth: CGFloat
        let scaledHeight: CGFloat

        if viewAspectRatio > imageAspectRatio {
            scaledWidth = size.width
            scaledHeight = size.width / imageAspectRatio
        } else {
            scaledHeight = size.height
            scaledWidth = size.height * imageAspectRatio
        }

        let xOffset = (scaledWidth - size.width) / 2
        let yOffset = (scaledHeight - size.height) / 2

        let minX = box.minX * scaledWidth - xOffset
        let maxX = box.maxX * scaledWidth - xOffset
        let minY = box.minY * scaledHeight - yOffset
        let maxY = box.maxY * scaledHeight - yOffset

        return minX >= 0 && maxX <= size.width && minY >= 0 && maxY <= size.height
    }

    private func shutterTapped() {
        guard !isCapturing, countdown == nil, hasHighConfidenceDetection else { return }
        captureAndSmartCrop()
    }
    
    private func captureAndSmartCrop() {
        guard !isCapturing else { return }
        isCapturing = true
        
        let currentBoundingBox = cameraManager.detectedObjects.first(where: { $0.confidence >= 0.80 && isFullyInPreview($0.boundingBox) })?.boundingBox
        triggerShutterEffect()
        
        cameraManager.capturePhoto { image in
            guard let originalImage = image else {
                finishCapture(with: nil)
                return
            }
            
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
        isCapturing = false
        withAnimation(.easeIn(duration: 0.2)) { showShutterFlash = false }
        capturedImage = finalImage
        // RootView observes capturedImage via onChange and drives the transition.
    }
    
    private func cropImage(_ image: UIImage, toRect boundingBox: CGRect) -> UIImage? {
        guard let fixedImage = fixedOrientation(for: image),
              let cgImage = fixedImage.cgImage else { return nil }
        
        let imageWidth = fixedImage.size.width
        let imageHeight = fixedImage.size.height
        
        let x = boundingBox.origin.x * imageWidth
        let width = boundingBox.width * imageWidth
        let height = boundingBox.height * imageHeight
        let y = boundingBox.origin.y * imageHeight
        
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return image }
        return UIImage(cgImage: croppedCgImage, scale: fixedImage.scale, orientation: fixedImage.imageOrientation)
    }
    
    private func fixedOrientation(for image: UIImage) -> UIImage? {
        guard image.imageOrientation != .up else { return image }
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        image.draw(in: CGRect(origin: .zero, size: image.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized
    }
}

// MARK: - Corner Brackets overlay

private struct CornerBracketsView: View {
    private let length: CGFloat = 40
    private let thickness: CGFloat = 6
    private let inset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            ZStack {
                // Top Left
                bracket(at: CGPoint(x: inset, y: inset), rotation: 0)
                // Top Right
                bracket(at: CGPoint(x: w - length - inset, y: inset), rotation: 90)
                // Bottom Right
                bracket(at: CGPoint(x: w - length - inset, y: h - length - inset), rotation: 180)
                // Bottom Left
                bracket(at: CGPoint(x: inset, y: h - length - inset), rotation: 270)
            }
        }
    }
    
    private func bracket(at point: CGPoint, rotation: Double) -> some View {
        BracketShape(length: length, thickness: thickness)
            .fill(Color.color3)
            .frame(width: length, height: length)
            .rotationEffect(.degrees(rotation))
            .position(x: point.x + length / 2, y: point.y + length / 2)
    }
}

private struct BracketShape: Shape {
    let length: CGFloat
    let thickness: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Vertical arm
        path.addRect(CGRect(x: 0, y: 0, width: thickness, height: length))
        // Horizontal arm
        path.addRect(CGRect(x: 0, y: 0, width: length, height: thickness))
        return path
    }
}
