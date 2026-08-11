//
//  PaintingCardView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 11/08/26.
//

import SwiftUI
import UIKit

struct PaintingCardView: View {

    let image: UIImage?
    let title: String
    let artist: String
    let year: String
    let location: String
    let captureDate: String

    private let cardWidth: CGFloat = 253
    private let cardHeight: CGFloat = 410
    private let cornerRadius: CGFloat = 12

    var body: some View {
        ZStack {

            // MARK: - Solid Shadow
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    Color(
                        red: 0.85,
                        green: 0.84,
                        blue: 0.81
                    )
                )
                .offset(x:4, y: 6)

            // MARK: - Main Card
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Location + Drag Handle
                HStack(alignment: .center) {

                    HStack(spacing: 6) {

                        Image("place")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundStyle(Color.color3)
                            .scaledToFit()
                            .frame(width: 16, height: 16)

                        Text(location)
                            .font(
                                .system(
                                    size: 12,
                                    weight: .regular
                                )
                            )
                            .foregroundStyle(
                                .black.opacity(0.9)
                            )
                            .lineLimit(1)
                    }

                    Spacer()

                    // Drag Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(
                            Color.gray.opacity(0.8)
                        )
                        .frame(
                            width: 22,
                            height: 5
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                // MARK: - Painting Image
                if let uiImage = image {

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: 196,
                            height: 233
                        )
                        .frame(
                            maxWidth: .infinity
                        )

                } else {

                    // Placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            Color.gray.opacity(0.12)
                        )
                        .frame(
                            width: 196,
                            height: 233
                        )
                        .overlay {
                            Image(systemName: "photo")
                                .font(
                                    .system(
                                        size: 32,
                                        weight: .regular
                                    )
                                )
                                .foregroundStyle(
                                    .gray.opacity(0.4)
                                )
                        }
                        .frame(
                            maxWidth: .infinity
                        )
                }

                // MARK: - Painting Information
                VStack(
                    alignment: .leading,
                    spacing: 4
                ) {

                    Text(title)
                        .font(
                            .system(
                                size: 14,
                                weight: .medium
                            )
                        )
                        .foregroundStyle(.black)
                        .lineLimit(1)

                    Text(artist)
                        .font(
                            .system(
                                size: 12,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            .black.opacity(0.8)
                        )
                        .lineLimit(1)

                    Text(year)
                        .font(
                            .system(
                                size: 10,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(
                            .black.opacity(0.8)
                        )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer(minLength: 0)

                // MARK: - Capture Date
                Text(captureDate)
                    .font(
                        .system(
                            size: 12,
                            weight: .regular
                        )
                    )
                    .foregroundStyle(
                        .black.opacity(0.6)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
            }
            .frame(
                width: cardWidth,
                height: cardHeight
            )
            .background(Color.white)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius
                )
            )
        }
        .frame(
            width: cardWidth,
            height: cardHeight
        )
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

#Preview {
    PaintingCardView(
        image: UIImage(named: "radensaleh"),
        title: "Girl With Pearl Earring",
        artist: "Johannes Vermeer",
        year: "1665",
        location: "Mauritshuis, Netherlands",
        captureDate: "8 August 2026"
    )
}
