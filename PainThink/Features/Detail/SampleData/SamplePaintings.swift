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
            ("kalau anting itu mutiara", "😮", "Takjub", "#B99B63", "Rani"),
            ("kalau anting itu mutiara", "😌", "Tenang", "#E4D5A8", "Bagas"),
            ("kalau anting itu mutiara", "😮", "Takjub", "#B99B63", "Nadia"),
            ("kalau anting itu mutiara", "🥰", "Hangat", "#7B86C4", "Fajar"),
            ("kalau anting itu mutiara", "😌", "Tenang", "#E4D5A8", "Sari"),
            ("kalau anting itu mutiara", "😮", "Takjub", "#B99B63", "Dimas"),
            ("kalau anting itu mutiara", "😢", "Haru", "#1C1C1C", "Ayu"),
            ("kalau dia sedang menoleh", "😌", "Tenang", "#E4D5A8", "Reza"),
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
