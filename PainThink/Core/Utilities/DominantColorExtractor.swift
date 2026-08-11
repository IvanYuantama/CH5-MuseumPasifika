//
//  DominantColorExtractor.swift
//  PainThink
//

import UIKit

enum DominantColorExtractor {
    // Downsamples the image and buckets quantized pixels to approximate its dominant colors.
    static func extractPalette(from image: UIImage, count: Int = 4) -> [UIColor] {
        guard let cgImage = image.cgImage else { return [] }

        let side = 40
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData = [UInt8](repeating: 0, count: side * side * 4)

        guard let context = CGContext(
            data: &pixelData,
            width: side,
            height: side,
            bitsPerComponent: 8,
            bytesPerRow: side * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return [] }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))

        func quantize(_ component: UInt8) -> UInt8 { (component / 32) * 32 }

        var buckets: [UInt32: Int] = [:]
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            guard pixelData[i + 3] > 10 else { continue }
            let r = quantize(pixelData[i])
            let g = quantize(pixelData[i + 1])
            let b = quantize(pixelData[i + 2])
            let key = UInt32(r) << 16 | UInt32(g) << 8 | UInt32(b)
            buckets[key, default: 0] += 1
        }

        return buckets
            .sorted { $0.value > $1.value }
            .prefix(count)
            .map { key, _ in
                UIColor(
                    red: CGFloat((key >> 16) & 0xFF) / 255,
                    green: CGFloat((key >> 8) & 0xFF) / 255,
                    blue: CGFloat(key & 0xFF) / 255,
                    alpha: 1
                )
            }
    }
}
