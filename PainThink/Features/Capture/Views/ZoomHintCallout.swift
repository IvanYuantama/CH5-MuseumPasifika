//
//  ZoomHintCallout.swift
//  PainThink
//

import SwiftUI

// Petunjuk "cincinnya bisa diputer buat zoom".
//
// Sengaja BUKAN TipKit: TipKit dirancang buat tampil sekali lalu diingat
// selamanya, sedangkan yang dibutuhin di sini kebalikannya — muncul lagi tiap
// kali layar kamera dibuka. Dengan view sendiri, kita juga bebas naruh ekor
// panah tepat di atas shutter.
struct ZoomHintCallout: View {

    /// Ikut berputar pelan biar gesture "puter" kebaca tanpa perlu baca teks.
    @State private var spin = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 7) {
                Image(systemName: "arrow.trianglehead.clockwise")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.color3)
                    .rotationEffect(.degrees(spin ? 360 : 0))
                    .animation(
                        .easeInOut(duration: 2.2).repeatForever(autoreverses: false),
                        value: spin
                    )

                Text("Turn the ring to zoom")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.black)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.22), radius: 8, y: 3)
            )

            // Ekor kecil yang nunjuk ke shutter di bawahnya.
            CalloutTail()
                .fill(.white)
                .frame(width: 12, height: 6)
        }
        .onAppear { spin = true }
        .allowsHitTesting(false)   // jangan sampai nutupin gesture shutter
    }
}

private struct CalloutTail: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
