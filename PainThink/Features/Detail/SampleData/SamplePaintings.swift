//
//  SamplePaintings.swift
//  PainThink
//

import Foundation

// Synthetic fixtures for previews only -- nothing in the shipping path reads
// this. Swap for the real feed once the backend can serve paintings.
enum SamplePaintings {
    static let girlWithPearlEarring = Painting(
        title: "Girl With Pearl Earring",
        artist: "Johannes Vermeer",
        year: "1665",
        museum: "Mauritshuis, Netherlands",
        assetName: nil,
        likeCount: 172_200
    )

    static let starryNight = Painting(
        title: "The Starry Night",
        artist: "Vincent van Gogh",
        year: "1889",
        museum: "Modern Art, United States",
        assetName: nil,
        likeCount: 208_400
    )

    // Weighted so one statement clearly wins and the moods spread unevenly --
    // a flat distribution would hide layout problems the real data will expose.
    static let pearlEarringOpinions: [VisitorOpinion] = {
        let hour: TimeInterval = 3_600

        let recipe: [(statement: String, emoji: String, mood: String, hex: String, name: String)] = [
            ("the earring is a pearl", "😮", "Amazed", "#B99B63", "Rani"),
            ("the earring is a pearl", "😌", "Calm", "#E4D5A8", "Bagas"),
            ("the earring is a pearl", "😮", "Amazed", "#B99B63", "Nadia"),
            ("the earring is a pearl", "🥰", "Warm", "#7B86C4", "Fajar"),
            ("the earring is a pearl", "😌", "Calm", "#E4D5A8", "Sari"),
            ("the earring is a pearl", "😮", "Amazed", "#B99B63", "Dimas"),
            ("the earring is a pearl", "😢", "Touched", "#1C1C1C", "Ayu"),
            ("she just turned around", "😌", "Calm", "#E4D5A8", "Reza"),
        ]

        return recipe.enumerated().map { index, item in
            VisitorOpinion(
                statement: item.statement,
                emoji: item.emoji,
                moodLabel: item.mood,
                colorHex: item.hex,
                visitorName: item.name,
                createdAt: Date().addingTimeInterval(-Double(index + 1) * hour)
            )
        }
    }()
}
