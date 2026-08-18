//
//  CameraPermissionDeniedView.swift
//  PainThink
//

import SwiftUI

// Shown when the user has denied camera access.
// Matches the design: yellow icon circle, bold headline, two action buttons.
struct CameraPermissionDeniedView: View {
    let onNotNow: () -> Void

    var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                VStack(alignment: .leading, spacing: 16) {
                    // Icon: yellow circle + camera.fill + diagonal strikethrough
                    ZStack {
                        Circle()
                            .fill(Color.color3)

                        Image(systemName: "camera.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)

                        // Diagonal strikethrough — clipped to the circle by the outer clipShape
                        Rectangle()
                            .fill(Color.black.opacity(0.32))
                            .frame(width: 3, height: 90)
                            .rotationEffect(.degrees(-45))
                    }
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())

                    // Headline
                    Text("The camera is\nturned off.")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.black)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtitle
                    Text("The questions come from your own shot.\nNo photo, nothing to develop.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open settings")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.color3, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open camera settings")

                    Button(action: onNotNow) {
                        Text("Not now")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(.black.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 56)
            }
        }
    }
}
