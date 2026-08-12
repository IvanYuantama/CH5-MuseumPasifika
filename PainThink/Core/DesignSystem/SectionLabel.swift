//
//  SectionLabel.swift
//  PainThink
//

import SwiftUI

// Small uppercase caption that sits above a group of cards. Kept quiet on
// purpose so the numbers and artwork below it carry the hierarchy.
struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .kerning(0.8)
            .foregroundStyle(.black.opacity(0.42))
    }
}
