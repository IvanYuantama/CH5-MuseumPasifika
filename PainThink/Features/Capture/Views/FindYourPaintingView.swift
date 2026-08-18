//
//  FindYourPaintingView.swift
//  PainThink
//

import SwiftUI

// Onboarding/landing screen shown once at app launch before the camera.
// Matches the design: large bold headline, calm subtitle, yellow Continue button.
struct FindYourPaintingView: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            Color.color1.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer()

                // Headline
                VStack(alignment: .leading, spacing: 16) {
                    Text("Find your\npainting.")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundStyle(.black)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Any one in this room. The one that keeps\nyou standing there a second too long.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.black.opacity(0.5))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 32)

                Spacer()

                // CTA
                Button(action: onContinue) {
                    Text("Continue")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.color3, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 48)
                .padding(.bottom, 56)
                .accessibilityLabel("Continue to camera")
            }
        }
    }
}
