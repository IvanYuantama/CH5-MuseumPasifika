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

    private static func paletteOptions(for image: UIImage) -> [PaletteMoodOption] {
        var palette = DominantColorExtractor.extractPalette(from: image, count: 4).map { Color($0) }

        // Pertahankan sebanyak mungkin warna asli foto, lalu isi slot yang
        // kosong supaya UI selalu mempunyai tepat empat highlight.
        if palette.count < 4 {
            palette.append(contentsOf: fallbackPalette.prefix(4 - palette.count))
        }

        return palette.prefix(4).enumerated().map { index, color in
            PaletteMoodOption(color: color, moodLabel: colorMoodLabels[index])
        }
    }

    static func generateActivities(for image: UIImage) -> [Activity] {
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
                paletteOptions: paletteOptions(for: image)
            ),
            Activity(
                kind: .emojiMood,
                prompt: "What mood do you sense from this painting?",
                emojiOptions: Array(emojiMoodOptions.shuffled().prefix(5))
            ),
        ]
    }

    // Maps the matched painting's backend question set onto `Activity`. "color"
    // questions ship with no answers by contract — their options come from
    // the same on-device dominant-color extraction used by the local fallback.
    static func makeActivities(from questions: [QuestionDTO], image: UIImage) -> [Activity] {
        return questions.compactMap { question in
            switch question.type {
            case "dragdrop":
                return Activity(
                    kind: .dragAndDrop,
                    prompt: question.text,
                    dragOptions: question.answers.map(\.label),
                    questionID: question.id
                )
            case "emoji":
                return Activity(
                    kind: .emojiMood,
                    prompt: question.text,
                    emojiOptions: question.answers.map { EmojiMoodOption(emoji: $0.value, moodLabel: $0.label) },
                    questionID: question.id
                )
            case "color":
                return Activity(
                    kind: .colorPaletteMood,
                    prompt: question.text,
                    paletteOptions: paletteOptions(for: image),
                    questionID: question.id
                )
            default:
                return nil
            }
        }
    }
}
