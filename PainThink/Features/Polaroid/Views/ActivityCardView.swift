//
//  ActivityCardView.swift
//  PainThink
//

import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    let selectedLabel: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .bottomTrailing) {
                Text(activity.prompt)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.black.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 16)
                    .padding(.trailing, selectedLabel != nil ? 32 : 16)
                    .padding(.vertical, 13)
                    .stickerCard(cornerRadius: 10)

                if selectedLabel != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.color3)
                        .padding(.trailing, 10)
                        .padding(.bottom, 8)
                }
            }

            switch activity.kind {
            case .emojiMood:
                EmojiMoodPickerView(activity: activity, selectedLabel: selectedLabel, onSelect: onSelect)
            case .colorPaletteMood:
                PaletteMoodPickerView(activity: activity, selectedLabel: selectedLabel, onSelect: onSelect)
            case .dragAndDrop:
                DragDropMoodPickerView(activity: activity, selectedLabel: selectedLabel, onSelect: onSelect)
            }
        }
    }
}
