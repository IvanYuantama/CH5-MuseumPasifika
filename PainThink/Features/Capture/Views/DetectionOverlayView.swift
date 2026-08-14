//
//  DetectionOverlayView.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI

struct DetectionOverlayView: View {
    let objects: [DetectedObject]

    var body: some View {
        GeometryReader { geo in
            ForEach(objects) { object in
                let rect = convert(object.boundingBox, in: geo.size)

                Rectangle()
                    .stroke(Color.brass, lineWidth: 2.5)
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .overlay(alignment: .topLeading) {
                        Text("\(object.label) \(Int(object.confidence * 100))%")
                            .font(.caption2.bold())
                            .foregroundStyle(Color.white) // Ganti sesuai Color.warmWhite kamu
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brass, in: Capsule())
                            .offset(x: rect.minX, y: rect.minY - 20)
                    }
            }
        }
    }

    private func convert(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        let isLandscape = size.width > size.height
        
        // Asumsi resolusi kamera default adalah 16:9.
        // Jika session kamu menggunakan preset .photo, ubah angka ini menjadi 4.0/3.0 dan 3.0/4.0
        let imageAspectRatio: CGFloat = isLandscape ? (16.0 / 9.0) : (9.0 / 16.0)
        let viewAspectRatio = size.width / size.height

        var scaledWidth = size.width
        var scaledHeight = size.height

        // Simulasikan logika .resizeAspectFill
        if viewAspectRatio > imageAspectRatio {
            scaledWidth = size.width
            scaledHeight = size.width / imageAspectRatio
        } else {
            scaledHeight = size.height
            scaledWidth = size.height * imageAspectRatio
        }

        // Hitung area yang ter-crop (offset)
        let xOffset = (scaledWidth - size.width) / 2.0
        let yOffset = (scaledHeight - size.height) / 2.0

        // Petakan koordinat (0...1) ke ukuran gambar yang sudah di-scale, lalu kurangi dengan offset
        return CGRect(
            x: (boundingBox.minX * scaledWidth) - xOffset,
            y: (boundingBox.minY * scaledHeight) - yOffset,
            width: boundingBox.width * scaledWidth,
            height: boundingBox.height * scaledHeight
        )
    }
}
