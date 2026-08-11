//
//  EmojiMoodPickerView.swift
//  PainThink
//

import SwiftUI

struct EmojiMoodPickerView: View {
    let activity: Activity
    let selectedLabel: String?
    let onSelect: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(activity.emojiOptions) { option in
                let isSelected = selectedLabel == option.moodLabel
                Button {
                    onSelect(option.moodLabel)
                } label: {
                    Text(option.emoji)
                        .font(.system(size: 28))
                        .padding(10)
                        .background(
                            Circle().fill(isSelected ? Color.color3.opacity(0.35) : Color.black.opacity(0.05))
                        )
                        .overlay(
                            Circle().stroke(isSelected ? Color.color3 : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
