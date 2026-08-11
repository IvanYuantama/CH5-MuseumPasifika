//
//  Colors.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI

extension Color {
    // Aksen utama — kuningan/brass, nuansa lampu sorot museum
    static let brass = Color(red: 0.79, green: 0.64, blue: 0.15)

    // Background gelap ala ruang galeri malam hari
    static let galleryBackground = Color(red: 0.08, green: 0.08, blue: 0.10)

    // Teks utama di atas background gelap
    static let warmWhite = Color(red: 0.95, green: 0.94, blue: 0.90)

    // Overlay/scrim di atas preview kamera
    static let scrim = Color.black.opacity(0.35)
    
    
    // New Color from Design
    static let color1 = Color(red: 255 / 255, green: 251 / 255, blue: 245 / 255)
        static let color2 = Color(red: 255 / 255, green: 255 / 255, blue: 255 / 255)
        static let color3 = Color(red: 255 / 255, green: 207 / 255, blue: 0 / 255)
}
