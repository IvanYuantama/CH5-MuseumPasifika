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
                    Haptics.success()
                    onSelect(option.moodLabel)
                } label: {
                    ZStack {
                        // Drop shadow circle underneath
                        Circle()
                            .fill(Color.black.opacity(0.15))
                            .frame(width: 44, height: 44)
                            .offset(x: 2, y: 3)
                        
                        // Main color circle
                        Circle()
                            .fill(option.color)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle().stroke(isSelected ? Color.black : Color.clear, lineWidth: isSelected ? 2 : 0)
                            )
                    }
                    .scaleEffect(isSelected ? 1.05 : 1)
                }
                .buttonStyle(.plain)
                .animation(.easeOut(duration: 0.15), value: isSelected)
            }
        }
    }
}
