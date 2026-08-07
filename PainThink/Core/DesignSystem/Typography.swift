//
//  Typography.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import SwiftUI

extension Font {
    // Dipakai untuk chrome UI standar (tombol, label kecil)
    static func uiLabel(_ size: CGFloat = 16, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight)
    }

    // Sentuhan "label galeri" — dipakai TERBATAS, misal caption viewfinder saja
    static func museumCaption(_ style: Font.TextStyle = .footnote) -> Font {
        .system(style, design: .serif)
    }
}
