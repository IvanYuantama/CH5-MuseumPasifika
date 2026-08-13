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
        EmojiMoodOption(emoji: "😍", moodLabel: "Enchanted"),
        EmojiMoodOption(emoji: "😌", moodLabel: "Calm"),
        EmojiMoodOption(emoji: "😮", moodLabel: "Amazed"),
        EmojiMoodOption(emoji: "😢", moodLabel: "Touched"),
        EmojiMoodOption(emoji: "😴", moodLabel: "Sleepy"),
        EmojiMoodOption(emoji: "😡", moodLabel: "Angry"),
        EmojiMoodOption(emoji: "🥰", moodLabel: "Warm"),
    ]

    private static let fallbackPalette: [Color] = [.orange, .teal, .purple, .pink]

    private static let colorMoodLabels = [
        "Happy", "Calm", "Excited", "Melancholic", "Mysterious", "Warm", "Bold", "Peaceful",
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

        let dragOptions = Array(emojiMoodOptions.shuffled().prefix(4)).map(\.moodLabel)

        return [
            Activity(
                kind: .emojiMood,
                prompt: "How do you feel looking at this painting?",
                emojiOptions: Array(emojiMoodOptions.shuffled().prefix(5))
            ),
            Activity(
                kind: .dragAndDrop,
                prompt: "Drag the mood that best describes this painting into the answer box",
                dragOptions: dragOptions
            ),
            Activity(
                kind: .colorPaletteMood,
                prompt: "Which color from this painting best matches your feeling?",
                paletteOptions: paletteOptions()
            ),
            Activity(
                kind: .emojiMood,
                prompt: "What mood do you sense from this painting?",
                emojiOptions: Array(emojiMoodOptions.shuffled().prefix(5))
            ),
        ]
    }
}
