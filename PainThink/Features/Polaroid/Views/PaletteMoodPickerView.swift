//
//  PaletteMoodPickerView.swift
//  PainThink
//

import SwiftUI

struct PaletteMoodPickerView: View {
    let activity: Activity
    let selectedLabel: String?
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 14) {
            ForEach(activity.paletteOptions) { option in
                let isSelected = selectedLabel == option.moodLabel
                Button {
                    onSelect(option.moodLabel)
                } label: {
                    Circle()
                        .fill(option.color)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle().stroke(isSelected ? Color.color3 : Color.black.opacity(0.15), lineWidth: isSelected ? 3 : 1)
                        )
                        .scaleEffect(isSelected ? 1.1 : 1)
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.15), value: isSelected)
            }
        }
    }
}
