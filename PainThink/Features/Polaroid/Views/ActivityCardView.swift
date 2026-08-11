//
//  ActivityCardView.swift
//  PainThink
//

import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    let index: Int
    let selectedLabel: String?
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Aktivitas \(index)")
                    .font(.uiLabel(12, weight: .bold))
                    .foregroundStyle(Color.brass)
                Spacer()
                if selectedLabel != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.brass)
                }
            }

            Text(activity.prompt)
                .font(.uiLabel(15))
                .foregroundStyle(Color.warmWhite)

            switch activity.kind {
            case .emojiMood:
                EmojiMoodPickerView(activity: activity, selectedLabel: selectedLabel, onSelect: onSelect)
            case .colorPaletteMood:
                PaletteMoodPickerView(activity: activity, selectedLabel: selectedLabel, onSelect: onSelect)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14))
    }
}
