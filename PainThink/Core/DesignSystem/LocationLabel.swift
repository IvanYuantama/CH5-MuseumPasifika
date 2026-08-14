//
//  LocationLabel.swift
//  PainThink
//

import SwiftUI

struct LocationLabel: View {
    let place: String
    var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 5) {
            Image("placeicon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(Color.color3)

            Text(place)
                .font(.system(size: size, weight: .light))
                .foregroundStyle(.black)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Lokasi: \(place)")
    }
}
