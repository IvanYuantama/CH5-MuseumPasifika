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
        VStack(alignment: .leading, spacing: 16) {
            Text("Color Feelings")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            HStack(spacing: 24) {
                ForEach(feelings, id: \.id) { feeling in
                    VStack(spacing: 16) {
                        // Lingkaran warna dengan drop shadow
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.15))
                                .frame(width: circleSize, height: circleSize)
                                .offset(x: 2, y: 3)
                                
                            Circle()
                                .fill(feeling.color)
                                .frame(width: circleSize, height: circleSize)
                                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                                .accessibilityLabel(feeling.label)
                        }
                        
                        // Bilah vertikal (Bar Chart)
                        GeometryReader { geometry in
                            ZStack(alignment: .bottom) {
                                Capsule()
                                    .fill(Color(red: 217/255, green: 217/255, blue: 217/255))
                                    .frame(width: barWidth, height: barHeight)
                                
                                Capsule()
                                    .fill(barColor)
                                    .frame(width: barWidth, height: barHeight * 0.6) // Sementara
                            }
                        }
                        .frame(width: barWidth, height: barHeight)
                    }
                }
            }
            // Mengubah frame menjadi nilai absolut 273, padding horizontal 60 dihapus
            .frame(width: 273)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
            )
            .stickerCard(cornerRadius: 20, shadowOffset: CGSize(width: 5, height: 6))
        }
    }
}
