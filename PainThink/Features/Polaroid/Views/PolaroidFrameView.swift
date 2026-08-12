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
    
    private let cardWidth: CGFloat = 300
    private let cornerRadius: CGFloat = 6
    private let borderWidth: CGFloat = 16
    private var photoSize: CGFloat { cardWidth - borderWidth * 2 }

    private var developOpacity: Double {
        guard total > 0 else { return 0 }
        return Double(total - progress) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            locationRow
                .padding(.horizontal, borderWidth)
                .padding(.top, 14)
                .padding(.bottom, 10)
            
            photo
                .padding(.horizontal, borderWidth)
            
            caption
                .padding(.horizontal, borderWidth)
                .padding(.top, 18)
                .padding(.bottom, 24)
        }
        .frame(width: cardWidth)
        .stickerCard(cornerRadius: cornerRadius, shadowOffset: CGSize(width: 5, height: 6))
        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isUnlocked)
        .animation(.easeInOut(duration: 0.6), value: progress)
        .frame(maxWidth: .infinity)
    }
    
    private var locationRow: some View {
        HStack(spacing: 5) {
            Image("placeicon")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(Color.color3)
                .scaledToFit()
                .frame(width: 16, height: 16)
            Text(location)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.black.opacity(0.8))
                .lineLimit(1)
            Spacer()
        }
    }
    
    private var photo: some View {
        ZStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: photoSize, height: photoSize)
                .clipShape(RoundedRectangle(cornerRadius: 2))

            RoundedRectangle(cornerRadius: 2)
                .fill(Color.black)
                .frame(width: photoSize, height: photoSize)
                .opacity(developOpacity)
        }
    }
    
    private var caption: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
            
            Text("\(artist) · \(year)")
                .font(.museumCaption(.footnote))
                .foregroundStyle(.black.opacity(0.65))
                .lineLimit(1)
            
            Text(captureDate)
                .font(.museumCaption(.caption2))
                .foregroundStyle(.black.opacity(0.5))
        }
    }
}
