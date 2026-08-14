//
//  LocationLabel.swift
//  PainThink
//

import SwiftUI

// Yellow pin + place name. Every expo card, collection card and detail header
// opens with this line, so it lives in the design system rather than being
// re-typed per screen.
struct LocationLabel: View {
    let place: String
    var size: CGFloat = 11

    var body: some View {
        HStack(spacing: 5) {
            Image("placeicon")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 6, height: 9)
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
