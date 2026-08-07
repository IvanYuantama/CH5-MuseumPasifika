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
                            .foregroundStyle(Color.warmWhite)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.brass, in: Capsule())
                            .offset(x: rect.minX, y: rect.minY - 20)
                    }
            }
        }
    }

    /// Vision pakai koordinat normalized dengan origin KIRI-BAWAH,
    /// SwiftUI pakai origin KIRI-ATAS -- makanya perlu flip Y.
    private func convert(_ boundingBox: CGRect, in size: CGSize) -> CGRect {
        CGRect(
            x: boundingBox.minX * size.width,
            y: (1 - boundingBox.maxY) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )
    }
}
