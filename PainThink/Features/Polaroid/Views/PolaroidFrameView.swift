//
//  PolaroidFrameView.swift
//  PainThink
//

import SwiftUI

struct PolaroidFrameView: View {
    let image: UIImage
    let isUnlocked: Bool
    let progress: Int
    let total: Int
    let caption: String?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 260)
                    .clipped()

                if !isUnlocked {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.35))

                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(Color.warmWhite)
                        Text("\(progress)/\(total) aktivitas selesai")
                            .font(.uiLabel(13))
                            .foregroundStyle(Color.warmWhite)
                    }
                }
            }
            .frame(height: 260)
            .clipped()

            HStack {
                Text(caption ?? (isUnlocked ? "Polaroid terbuka! 🎉" : "Selesaikan aktivitas untuk membuka"))
                    .font(.museumCaption())
                    .foregroundStyle(.black.opacity(0.7))
                Spacer()
            }
            .padding(.top, 14)
            .padding(.bottom, 20)
            .padding(.horizontal, 14)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 8)
        .rotationEffect(.degrees(isUnlocked ? 0 : -1.5))
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isUnlocked)
        .padding(.horizontal, 24)
    }
}
