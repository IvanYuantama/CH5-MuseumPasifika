//
//  PolaroidFrameView.swift
//  PainThink
//

import SwiftUI

struct PolaroidFrameView: View {
    let image: UIImage
    let title: String
    let artist: String
    let year: String
    let location: String
    let captureDate: String
    let isUnlocked: Bool
    let progress: Int
    let total: Int
    
    private let cardWidth: CGFloat = 280
    private let cornerRadius: CGFloat = 8
    private let borderWidth: CGFloat = 14
    private var photoWidth: CGFloat { cardWidth - borderWidth * 2 }

    /// Tinggi foto mengikuti aspect ratio asli gambar hasil crop bounding box.
    /// Dibatasi agar tidak terlalu pendek (min 0.5:1) atau terlalu tinggi (max 2:1).
//    private var photoHeight: CGFloat {
//        let ratio = image.size.height / max(image.size.width, 1)
//        let clampedRatio = min(max(ratio, 0.5), 2.0)
//        return photoWidth * clampedRatio
//    }
    
    private let maxPhotoHeight: CGFloat = 320 // Batas maksimal agar kartu tidak meluber layar

    private var photoHeight: CGFloat {
        let ratio = image.size.height / max(image.size.width, 1)
        // Tinggi murni relatif terhadap lebar: hanya dibatasi maksimum, tidak ada minimum paksa
        return min(photoWidth * ratio, maxPhotoHeight)
    }

    private var developOpacity: Double {
        guard total > 0 else { return 0 }
        return Double(total - progress) / Double(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            locationRow
                .padding(.horizontal, borderWidth)
                .padding(.top, 14)
                .padding(.bottom, 29)

            photo
                .padding(.horizontal, borderWidth)

            caption
                .padding(.horizontal, borderWidth)
                .padding(.top, 14)
                .padding(.bottom, 20)
        }
        .frame(width: cardWidth)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white)
        )
        .stickerCard(
            cornerRadius: cornerRadius,
            shadowOffset: CGSize(width: 4, height: 6)
        )
        .animation(
            .spring(response: 0.6, dampingFraction: 0.7),
            value: isUnlocked
        )
        .animation(
            .easeInOut(duration: 0.6),
            value: progress
        )
        .frame(maxWidth: .infinity)
    }

    private var locationRow: some View {
        HStack(spacing: 5) {
            Image("placeicon")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.color3)
                .scaledToFit()
                .frame(width: 14, height: 14)

            Text(location)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
            
            Spacer()
            
            // Short horizontal line on the right
            Rectangle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 16, height: 2.5)
        }
    }

    private var photo: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()              // Tinggi mengikuti aspect ratio asli, tidak di-crop
            .frame(width: photoWidth)   // Width fixed, height relatif
            .clipShape(RoundedRectangle(cornerRadius: 2))
            // Overlay mengikuti ukuran photo secara otomatis
            .overlay {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .opacity(developOpacity)
            }
    }
    
    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)
            
            Text(artist)
                .font(.system(size: 12, weight: .regular, design: .rounded))
                .foregroundStyle(.black)
                .lineLimit(1)

            Text(year)
                .font(.system(size: 10, weight: .regular, design: .rounded))
                .foregroundStyle(.black)

            Color.clear.frame(height: 35)
            
            Text(captureDate)
                .font(.system(size: 12, weight: .light, design: .rounded))
                .foregroundStyle(.black.opacity(0.8))
        }
    }
}
