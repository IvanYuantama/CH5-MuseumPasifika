//
//  StickerCard.swift
//  PainThink
//

import SwiftUI

// The "sticker" look used across the post-capture screens: a flat card with a
// solid, offset shadow card behind it instead of a blurred drop shadow.
struct StickerCardBackground: ViewModifier {
    var cornerRadius: CGFloat = 10
    var shadowOffset: CGSize = CGSize(width: 3, height: 4)
    var fill: Color = .color2

    func body(content: Content) -> some View {
        content.background {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.85, green: 0.84, blue: 0.81))
                    .offset(x: shadowOffset.width, y: shadowOffset.height)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(fill)
            }
        }
    }
}

extension View {
    func stickerCard(
        cornerRadius: CGFloat = 10,
        shadowOffset: CGSize = CGSize(width: 3, height: 4),
        fill: Color = .color2
    ) -> some View {
        modifier(StickerCardBackground(cornerRadius: cornerRadius, shadowOffset: shadowOffset, fill: fill))
    }

    // A shadow cast inward from the shape's edge, so a filled shape reads as a
    // recessed hole/socket rather than a flat, raised card.
    func innerShadow(
        cornerRadius: CGFloat,
        color: Color = .black.opacity(0.4),
        radius: CGFloat = 5,
        offset: CGSize = CGSize(width: 0, height: 3)
    ) -> some View {
        overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(color, lineWidth: radius * 2)
                .offset(offset)
                .blur(radius: radius)
                .mask(RoundedRectangle(cornerRadius: cornerRadius))
        )
    }
}
