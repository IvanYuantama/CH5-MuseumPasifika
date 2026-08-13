import SwiftUI

// Instant-camera styled capture screen: the viewfinder sits in a card on warm
// paper, with an exposure ruler, timer presets, and a shutter knob below it.
// Adapts between portrait and landscape, so the old portrait lock is gone.
struct CameraView: View {
    @State private var cameraManager = CameraManager(detectionService: CoreMLArtworkDetectionService())
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var isCapturing = false
    @State private var showShutterFlash = false
    @State private var exposure: Double = 0
    @State private var timerSeconds: Int?
    @State private var countdown: Int?
    @State private var knobRotation: Double = 0
    @State private var lastKnobAngle: Double?

    private let knobSize: CGFloat = 96
    private let knobMaxRotation: Double = 270
    private let zoomRange: ClosedRange<Double> = 1...5

    private var zoomFactor: Double {
        zoomRange.lowerBound + knobRotation / knobMaxRotation * (zoomRange.upperBound - zoomRange.lowerBound)
    }

    private var isLandscape: Bool { verticalSizeClass == .compact }

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.color1.ignoresSafeArea()

            if cameraManager.permissionDenied {
                permissionDeniedView
            } else if isLandscape {
                landscapeLayout
            } else {
                portraitLayout
            }

            closeButton
        }
        .onAppear { cameraManager.configure() }
        .onDisappear { cameraManager.stopSession() }
        .onChange(of: exposure) { _, newValue in
            cameraManager.setExposureBias(Float(newValue))
        }
    }

    // MARK: - Layouts

    private var portraitLayout: some View {
        VStack(spacing: 0) {
            previewCard
                .padding(.horizontal, 24)
                .padding(.top, 52)

            infoLabels
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 28)
                .padding(.top, 12)

            ExposureRuler(value: $exposure)
                .frame(width: 224)
                .padding(.top, 30)

            Spacer()

            shutterKnob
                .frame(maxWidth: .infinity)
                .overlay(alignment: .leading) {
                    timerColumn.padding(.leading, 64)
                }
                .padding(.bottom, 44)
        }
    }

    private var landscapeLayout: some View {
        HStack(spacing: 28) {
            previewCard
                .padding(.leading, 34)
                .padding(.vertical, 18)

            VStack(alignment: .leading, spacing: 0) {
                infoLabels
                    .padding(.top, 14)

                Spacer()

                shutterKnob
                    .frame(maxWidth: .infinity)
                    .overlay(alignment: .trailing) {
                        timerColumn
                    }

                Spacer()

                ExposureRuler(value: $exposure)
                    .frame(width: 190)
                    .padding(.bottom, 14)
            }
            .padding(.trailing, 36)
        }
    }

    // MARK: - Viewfinder

    private var previewCard: some View {
        ZStack {
            if cameraManager.isSessionRunning {
                CameraPreviewView(session: cameraManager.session)
            } else {
                // Simulator, or the session still warming up.
                Color.black
            }

            if cameraManager.isLiveDetectionEnabled {
                DetectionOverlayView(objects: cameraManager.detectedObjects)
            }

            if let countdown {
                Text("\(countdown)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
                    .contentTransition(.numericText(countsDown: true))
            }

            Color.white
                .opacity(showShutterFlash ? 0.8 : 0)
                .allowsHitTesting(false)
        }
        .aspectRatio(isLandscape ? 1.5 : 1.0, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .animation(.easeInOut(duration: 0.2), value: countdown)
    }

    private var infoLabels: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Exposure : \(String(format: "%.1f", exposure))")
            Text("Timer : \(timerSeconds.map { "\($0) s" } ?? "off")")
            Text("Zoom : \(String(format: "%.1f", zoomFactor))x")
        }
        .font(.system(size: 11))
        .foregroundStyle(.black.opacity(0.55))
    }

    // MARK: - Controls

    private var timerColumn: some View {
        VStack(spacing: 16) {
            timerButton(3)
            timerButton(5)
        }
    }

    private func timerButton(_ seconds: Int) -> some View {
        let isSelected = timerSeconds == seconds
        return Button {
            timerSeconds = isSelected ? nil : seconds
        } label: {
            Text("\(seconds)s")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.black.opacity(0.75))
                .frame(width: 42, height: 42)
                .background(
                    Circle().fill(
                        isSelected
                            ? Color(red: 0.72, green: 0.71, blue: 0.70)
                            : Color(red: 0.89, green: 0.88, blue: 0.87)
                    )
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(seconds) second timer")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // Tap fires the shutter; dragging in a circle rotates the dial and maps
    // 0...270 degrees onto 1x...5x zoom.
    private var shutterKnob: some View {
        Image("Puter")
            .resizable()
            .scaledToFit()
            .frame(width: knobSize, height: knobSize)
            .rotationEffect(.degrees(knobRotation))
            .scaleEffect(isCapturing ? 0.94 : 1)
            .contentShape(Circle())
            .gesture(knobRotateGesture)
            .onTapGesture(perform: shutterTapped)
            .animation(.easeOut(duration: 0.15), value: isCapturing)
            .accessibilityLabel("Shutter")
            .accessibilityHint("Tap to capture. Drag in a circle to zoom.")
    }

    private var knobRotateGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                let center = knobSize / 2
                let angle = atan2(value.location.y - center, value.location.x - center) * 180 / .pi
                if let last = lastKnobAngle {
                    var delta = angle - last
                    if delta > 180 { delta -= 360 }
                    if delta < -180 { delta += 360 }
                    knobRotation = min(knobMaxRotation, max(0, knobRotation + delta))
                    cameraManager.setZoom(Float(zoomFactor))
                }
                lastKnobAngle = angle
            }
            .onEnded { _ in lastKnobAngle = nil }
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.black.opacity(0.55))
                .padding(10)
                .background(Color.black.opacity(0.06), in: Circle())
        }
        .buttonStyle(.plain)
        .padding(.leading, 16)
        .padding(.top, 8)
        .accessibilityLabel("Close camera")
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "camera.fill").font(.system(size: 32)).foregroundStyle(Color.brass)
            Text("Camera access needed").font(.headline).foregroundStyle(.black)
            Text("Open Settings to allow camera access.")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.6))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.brass)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Capture

    private func shutterTapped() {
        guard !isCapturing, countdown == nil else { return }
        if let timerSeconds {
            startCountdown(from: timerSeconds)
        } else {
            captureAndSmartCrop()
        }
    }

    private func startCountdown(from seconds: Int) {
        countdown = seconds
        Task {
            for remaining in stride(from: seconds, through: 1, by: -1) {
                withAnimation { countdown = remaining }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
            countdown = nil
            captureAndSmartCrop()
        }
    }

    // Manual capture + smart crop: grabs the freshest bounding box at shutter
    // time and crops the photo to it; falls back to the full frame.
    private func captureAndSmartCrop() {
        guard !isCapturing else { return }
        isCapturing = true

        let currentBoundingBox = cameraManager.detectedObjects.first?.boundingBox

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

        // Converts the Y coordinate from Vision (bottom-left) to CoreGraphics (top-left).
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

// Ruler-style exposure slider: ticks from -2 to +2, a black handle, draggable
// across the whole strip. Writes EV directly to the binding.
private struct ExposureRuler: View {
    @Binding var value: Double

    private let range: ClosedRange<Double> = -2...2
    private let tickStep: Double = 0.25

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("- +")
                .font(.system(size: 9))
                .foregroundStyle(.black.opacity(0.4))

            GeometryReader { geo in
                let width = geo.size.width

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(.black.opacity(0.35))
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .center)

                    ForEach(ticks, id: \.self) { tick in
                        let isMajor = tick.truncatingRemainder(dividingBy: 1) == 0
                        Rectangle()
                            .fill(.black.opacity(isMajor ? 0.5 : 0.3))
                            .frame(width: 1, height: isMajor ? 14 : 8)
                            .frame(maxHeight: .infinity, alignment: .center)
                            .offset(x: position(of: tick, in: width))
                    }

                    RoundedRectangle(cornerRadius: 2)
                        .fill(.black)
                        .frame(width: 5, height: 18)
                        .offset(x: position(of: value, in: width) - 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { drag in
                            let raw = range.lowerBound
                                + (drag.location.x / width) * (range.upperBound - range.lowerBound)
                            let snapped = (raw * 10).rounded() / 10
                            value = min(range.upperBound, max(range.lowerBound, snapped))
                        }
                )
            }
            .frame(height: 20)

            HStack {
                Text("-2"); Spacer(); Text("-1"); Spacer(); Text("0"); Spacer(); Text("+1"); Spacer(); Text("+2")
            }
            .font(.system(size: 9))
            .foregroundStyle(.black.opacity(0.5))
        }
        .accessibilityElement()
        .accessibilityLabel("Exposure")
        .accessibilityValue(String(format: "%.1f", value))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: value = min(range.upperBound, value + 0.1)
            case .decrement: value = max(range.lowerBound, value - 0.1)
            @unknown default: break
            }
        }
    }

    private var ticks: [Double] {
        Array(stride(from: range.lowerBound, through: range.upperBound, by: tickStep))
    }

    private func position(of tick: Double, in width: CGFloat) -> CGFloat {
        let fraction = (tick - range.lowerBound) / (range.upperBound - range.lowerBound)
        return CGFloat(fraction) * width
    }
}
