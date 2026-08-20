//
//  Activity.swift
//  PainThink
//

import SwiftUI

// Activity content is generated locally for now; `kind` mirrors the type
// field the backend will eventually send per painting.
enum ActivityKind: String {
    case emojiMood
    case colorPaletteMood
    case dragAndDrop
}

struct EmojiMoodOption: Identifiable, Hashable {
    let id = UUID()
    let emoji: String
    let moodLabel: String
}

struct PaletteMoodOption: Identifiable, Hashable {
    let id = UUID()
    let color: Color
    let moodLabel: String
}

struct Activity: Identifiable {
    let id = UUID()
    let kind: ActivityKind
    let prompt: String
    var emojiOptions: [EmojiMoodOption] = []
    var paletteOptions: [PaletteMoodOption] = []
    var dragOptions: [String] = []
    // Backend question ID, set only when this activity was built from a
    // matched painting's real question set (nil for the local fallback set).
    var questionID: String? = nil
}
