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
        let count: Int
        let share: Double
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

        // Hanya jawaban dari picker bebas yang masuk bucket hue. Swatch foto
        // selalu memakai hex aslinya. Nilai lama belum memiliki source tag dan
        // diperlakukan sebagai picker agar hasil agregasi lama tetap konsisten.
        let normalizedColors = opinions.compactMap { opinion -> String? in
            guard let answer = opinion.colorHex.colorAnswer else { return nil }

            switch answer.source {
            case .photoPalette:
                return answer.hex
            case .customPicker, .legacy:
                return ColorGrouping.groupedHex(for: answer.hex)
            }
        }

        colorFeelings = Self.tally(normalizedColors)
            .prefix(paletteLimit)
            .map { entry in
                ColorFeeling(
                    hex: entry.value,
                    label: Self.colorName(forHex: entry.value),
                    count: entry.count,
                    share: Double(entry.count) / denominator
                )
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

    // MARK: - Color naming

    private static let hueSteps: Double = 12

    // Nama warna untuk tiap bucket (index 0–11, mulai dari merah di 0°).
    private static let bucketNames = [
        "Red", "Orange", "Yellow", "Chartreuse",
        "Green", "Spring Green", "Cyan", "Sky Blue",
        "Blue", "Purple", "Magenta", "Pink"
    ]

    /// Nama warna manusiawi untuk hex bucket.
    private static func colorName(forHex hex: String) -> String {
        let h = hue(of: Color(hex: hex))
        let bucketIndex = Int((h * hueSteps).rounded()) % Int(hueSteps)
        return bucketNames[bucketIndex]
    }

    /// Hue komponen (0...1) dari sebuah Color.
    private static func hue(of color: Color) -> Double {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Double(h)
    }
}
