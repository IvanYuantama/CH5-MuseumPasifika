//
//  ColorFeelingsCard.swift
//  PainThink
//

import SwiftUI

struct ColorFeelingsCard: View {
    // Mengembalikan properti ini agar PaintingDetailView bisa mengirimkan argumen
    let feelings: [PaintingInsights.ColorFeeling]

    private let circleSize: CGFloat = 36
    private let barWidth: CGFloat = 10
    private let barHeight: CGFloat = 120
    private let barColor = Color.yellow // Sesuaikan jika ada warna spesifik, misal: Color.color2
    private let trackColor = Color.black.opacity(0.15)

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            // Judul rata tengah sesuai referensi gambar
            Text("Color Feelings")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.black)
            
            HStack(spacing: 24) {
                ForEach(feelings, id: \.id) { feeling in
                    VStack(spacing: 12) {
                        // Lingkaran warna
                        Circle()
                            .fill(feeling.color)
                            .frame(width: circleSize, height: circleSize)
                            .accessibilityLabel(feeling.label)
                        
                        // Bilah vertikal (Bar Chart)
                        GeometryReader { geometry in
                            ZStack(alignment: .bottom) {
                                // Background bilah (Memperbaiki typo 'Capsul' menjadi 'Capsule')
                                Capsule()
                                    .fill(trackColor)
                                    .frame(width: barWidth, height: barHeight)
                                
                                // Isi bilah kuning
                                // CATATAN: Ganti '0.6' di bawah ini dengan properti kalkulasi sebenarnya
                                // dari model PaintingInsights.ColorFeeling Anda jika ada (misal: feeling.ratio).
                                Capsule()
                                    .fill(barColor)
                                    .frame(width: barWidth, height: barHeight * 0.6)
                            }
                        }
                        .frame(width: barWidth, height: barHeight)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        // Mempertahankan custom modifier bawaan dari project Anda
        .stickerCard(cornerRadius: 14, shadowOffset: CGSize(width: 4, height: 5))
    }
}
