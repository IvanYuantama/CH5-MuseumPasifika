//
//  SampleFeed.swift
//  PainThink
//

import Foundation

// Synthetic feed for previews and the temporary expo screen. Nothing in the
// shipping path reads this -- replace with the real query once paintings and
// opinions are served.


// Test no entry
//enum SampleFeed {
//    static let entries: [FeedEntry] = []
//    
//    // ...
//}

// Test with entry
enum SampleFeed {
    static let entries: [FeedEntry] = [
        entry(
            title: "Mona Lisa", artist: "Leonardo da Vinci", year: "1503",
            museum: "De Louvre, France", likes: 172_200, aspect: 0.68,
            winner: ("she is smiling", "😌", "Calm", "#4A3728"),
            runnerUp: ("she is judging us", "😮", "Amazed", "#8C7B52"),
            extras: [("🥰", "Warm", "#A88B6A"), ("😢", "Touched", "#6E4B3A")],
            winnerCount: 7
        ),
        entry(
            title: "The Starry Night", artist: "Vincent van Gogh", year: "1889",
            museum: "Modern Art, United States", likes: 208_400, aspect: 1.24,
            winner: ("there are stars in the sky", "😮", "Amazed", "#2A3D66"),
            runnerUp: ("the sky is swirling", "😌", "Calm", "#6E86C0"),
            extras: [("🥰", "Warm", "#B99B2E"), ("😴", "Sleepy", "#D6CE8A")],
            winnerCount: 5
        ),
        entry(
            title: "Penangkapan Diponegoro", artist: "Raden Saleh", year: "1857",
            museum: "Galeri Nasional, Indonesia", likes: 96_800, aspect: 1.42,
            winner: ("this depicts colonialism", "😡", "Angry", "#8C3B2A"),
            runnerUp: ("this is about farewell", "😢", "Touched", "#7B86C4"),
            extras: [("😮", "Amazed", "#C9A87C"), ("😌", "Calm", "#1C1C1C")],
            winnerCount: 8
        ),
        entry(
            title: "Girl With Pearl Earring", artist: "Johannes Vermeer", year: "1665",
            museum: "Mauritshuis, Netherlands", likes: 172_200, aspect: 0.8,
            winner: ("the earring is a pearl", "😮", "Amazed", "#B99B63"),
            runnerUp: ("she just turned around", "😌", "Calm", "#E4D5A8"),
            extras: [("🥰", "Warm", "#7B86C4"), ("😢", "Touched", "#1C1C1C")],
            winnerCount: 7
        ),
        entry(
            title: "The Scream", artist: "Edvard Munch", year: "1893",
            museum: "The Munch, Norway", likes: 121_200, aspect: 0.86,
            winner: ("this is about anxiety", "😢", "Touched", "#C4482A"),
            runnerUp: ("the sky is screaming too", "😡", "Angry", "#E08A2E"),
            extras: [("😮", "Amazed", "#2A4A6E"), ("😌", "Calm", "#3A3A5C")],
            winnerCount: 6
        ),
        entry(
            title: "The Great Wave", artist: "Katsushika Hokusai", year: "1831",
            museum: "Sumida Hokusai, Tokyo", likes: 172_200, aspect: 1.46,
            winner: ("the wave feels alive", "😮", "Amazed", "#1E4A6B"),
            runnerUp: ("this feels calming", "😌", "Calm", "#8CB4CE"),
            extras: [("🥰", "Warm", "#E8DCC0"), ("😴", "Sleepy", "#3A3A3A")],
            winnerCount: 7
        ),
    ]

    private static let names = [
        "Rani", "Bagas", "Nadia", "Fajar", "Sari", "Dimas", "Ayu", "Reza", "Putri", "Yoga",
    ]
    private static let hour: TimeInterval = 3_600

    // Weighted on purpose: `winner` repeats enough to dominate the headline, and
    // every third voter is swapped to an extra mood so the palette and the
    // distribution bars have something uneven to render.
    private static func entry(
        title: String, artist: String, year: String,
        museum: String, likes: Int, aspect: CGFloat,
        winner: (statement: String, emoji: String, mood: String, hex: String),
        runnerUp: (statement: String, emoji: String, mood: String, hex: String),
        extras: [(emoji: String, mood: String, hex: String)],
        winnerCount: Int
    ) -> FeedEntry {
        var opinions: [VisitorOpinion] = []

        for index in 0..<winnerCount {
            let swap = index.isMultiple(of: 3)
            opinions.append(
                VisitorOpinion(
                    statement: winner.statement,
                    emoji: swap ? extras[0].emoji : winner.emoji,
                    moodLabel: swap ? extras[0].mood : winner.mood,
                    colorHex: swap ? extras[0].hex : winner.hex,
                    visitorName: names[index % names.count],
                    createdAt: Date().addingTimeInterval(-Double(index + 1) * hour)
                )
            )
        }

        opinions.append(
            VisitorOpinion(
                statement: runnerUp.statement,
                emoji: runnerUp.emoji,
                moodLabel: runnerUp.mood,
                colorHex: runnerUp.hex,
                visitorName: names[winnerCount % names.count],
                createdAt: Date().addingTimeInterval(-Double(winnerCount + 1) * hour)
            )
        )

        opinions.append(
            VisitorOpinion(
                statement: winner.statement,
                emoji: extras[1].emoji,
                moodLabel: extras[1].mood,
                colorHex: extras[1].hex,
                visitorName: names[(winnerCount + 1) % names.count],
                createdAt: Date().addingTimeInterval(-Double(winnerCount + 2) * hour)
            )
        )

        return FeedEntry(
            painting: Painting(
                title: title, artist: artist, year: year,
                museum: museum, assetName: nil, likeCount: likes
            ),
            opinions: opinions,
            aspectRatio: aspect
        )
    }
}
