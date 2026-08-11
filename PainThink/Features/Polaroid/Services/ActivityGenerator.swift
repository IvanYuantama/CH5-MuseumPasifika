//
//  ActivityGenerator.swift
//  PainThink
//

import UIKit
import SwiftUI

// Builds the 4 mood-picker activities that must be completed to unlock a polaroid.
// Content is generated locally today; later this can be swapped for a backend
// call keyed by the detected painting without changing `Activity`'s shape.
enum ActivityGenerator {
    private static let emojiMoodOptions: [EmojiMoodOption] = [
        EmojiMoodOption(emoji: "😍", moodLabel: "Terpukau"),
        EmojiMoodOption(emoji: "😌", moodLabel: "Tenang"),
        EmojiMoodOption(emoji: "😮", moodLabel: "Takjub"),
        EmojiMoodOption(emoji: "😢", moodLabel: "Haru"),
        EmojiMoodOption(emoji: "😴", moodLabel: "Mengantuk"),
        EmojiMoodOption(emoji: "😡", moodLabel: "Marah"),
        EmojiMoodOption(emoji: "🥰", moodLabel: "Hangat"),
    ]

    private static let fallbackPalette: [Color] = [.orange, .teal, .purple, .pink]

    private static let colorMoodLabels = [
        "Bahagia", "Tenang", "Bersemangat", "Melankolis", "Misterius", "Hangat", "Berani", "Damai",
    ]

    static func generateActivities(for image: UIImage) -> [Activity] {
        var palette = DominantColorExtractor.extractPalette(from: image, count: 4).map { Color($0) }
        if palette.count < 3 {
            palette = fallbackPalette
        }

        func paletteOptions() -> [PaletteMoodOption] {
            palette.shuffled().enumerated().map { index, color in
                PaletteMoodOption(color: color, moodLabel: colorMoodLabels[index % colorMoodLabels.count])
            }
        }

        return [
            Activity(
                kind: .emojiMood,
                prompt: "Apa yang kamu rasakan saat melihat lukisan ini?",
                emojiOptions: Array(emojiMoodOptions.shuffled().prefix(5))
            ),
            Activity(
                kind: .colorPaletteMood,
                prompt: "Warna mana dari lukisan ini yang paling mewakili perasaanmu?",
                paletteOptions: paletteOptions()
            ),
            Activity(
                kind: .emojiMood,
                prompt: "Bagaimana suasana hati yang kamu tangkap dari lukisan ini?",
                emojiOptions: Array(emojiMoodOptions.shuffled().prefix(5))
            ),
            Activity(
                kind: .colorPaletteMood,
                prompt: "Pilih warna yang paling menarik perhatianmu dari lukisan ini",
                paletteOptions: paletteOptions()
            ),
        ]
    }
}
