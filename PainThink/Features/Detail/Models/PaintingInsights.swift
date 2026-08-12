//
//  PaintingInsights.swift
//  PainThink
//

import SwiftUI

// Turns a pile of individual opinions into the three numbers the detail screen
// shows. Pure and view-free on purpose: when the backend starts returning these
// aggregates instead, only the call site changes, not the UI.
struct PaintingInsights {
    struct Headline {
        let percentage: Int
        let statement: String
    }

    struct MoodTally: Identifiable {
        var id: String { label }
        let emoji: String
        let label: String
        let count: Int
        let share: Double
    }

    struct ColorFeeling: Identifiable {
        var id: String { hex }
        let hex: String
        let label: String
        var color: Color { Color(hex: hex) }
    }

    let total: Int
    let headline: Headline?
    let moods: [MoodTally]
    let colorFeelings: [ColorFeeling]

    init(opinions: [VisitorOpinion], paletteLimit: Int = 4) {
        total = opinions.count

        guard !opinions.isEmpty else {
            headline = nil
            moods = []
            colorFeelings = []
            return
        }

        let denominator = Double(opinions.count)

        headline = Self.tally(opinions.map(\.statement)).first.map { entry in
            Headline(
                percentage: Int((Double(entry.count) / denominator * 100).rounded()),
                statement: entry.value
            )
        }

        // Emoji is carried by the opinion, so look it up from the first sighting
        // of each label rather than tallying the pair.
        let emojiByLabel = Dictionary(
            opinions.map { ($0.moodLabel, $0.emoji) },
            uniquingKeysWith: { first, _ in first }
        )
        moods = Self.tally(opinions.map(\.moodLabel)).map { entry in
            MoodTally(
                emoji: emojiByLabel[entry.value] ?? "🎨",
                label: entry.value,
                count: entry.count,
                share: Double(entry.count) / denominator
            )
        }

        let labelByHex = Dictionary(
            opinions.map { ($0.colorHex, $0.moodLabel) },
            uniquingKeysWith: { first, _ in first }
        )
        colorFeelings = Self.tally(opinions.map(\.colorHex))
            .prefix(paletteLimit)
            .map { entry in
                ColorFeeling(hex: entry.value, label: labelByHex[entry.value] ?? entry.value)
            }
    }

    // Counts occurrences, most frequent first. Ties break by first appearance so
    // the same input always renders in the same order.
    private static func tally<Key: Hashable>(_ values: [Key]) -> [(value: Key, count: Int)] {
        var counts: [Key: Int] = [:]
        var firstSeen: [Key: Int] = [:]

        for (index, value) in values.enumerated() {
            counts[value, default: 0] += 1
            if firstSeen[value] == nil { firstSeen[value] = index }
        }

        return counts
            .map { (value: $0.key, count: $0.value) }
            .sorted { lhs, rhs in
                guard lhs.count == rhs.count else { return lhs.count > rhs.count }
                return (firstSeen[lhs.value] ?? 0) < (firstSeen[rhs.value] ?? 0)
            }
    }
}
