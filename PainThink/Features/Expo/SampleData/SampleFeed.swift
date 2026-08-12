//
//  SampleFeed.swift
//  PainThink
//

import Foundation

// Synthetic feed for previews and the temporary expo screen. Nothing in the
// shipping path reads this -- replace with the real query once paintings and
// opinions are served.
enum SampleFeed {
    static let entries: [FeedEntry] = [
        entry(
            title: "Mona Lisa", artist: "Leonardo da Vinci", year: "1503",
            museum: "De Louvre, France", likes: 172_200, aspect: 0.68,
            winner: ("wajahnya lagi tersenyum", "😌", "Tenang", "#4A3728"),
            runnerUp: ("dia lagi menilai kita", "😮", "Takjub", "#8C7B52"),
            extras: [("🥰", "Hangat", "#A88B6A"), ("😢", "Haru", "#6E4B3A")],
            winnerCount: 7
        ),
        entry(
            title: "The Starry Night", artist: "Vincent van Gogh", year: "1889",
            museum: "Modern Art, United States", likes: 208_400, aspect: 1.24,
            winner: ("ada bintang di langit", "😮", "Takjub", "#2A3D66"),
            runnerUp: ("langitnya sedang berputar", "😌", "Tenang", "#6E86C0"),
            extras: [("🥰", "Hangat", "#B99B2E"), ("😴", "Mengantuk", "#D6CE8A")],
            winnerCount: 5
        ),
        entry(
            title: "Penangkapan Diponegoro", artist: "Raden Saleh", year: "1857",
            museum: "Galeri Nasional, Indonesia", likes: 96_800, aspect: 1.42,
            winner: ("ini menggambarkan penjajahan", "😡", "Marah", "#8C3B2A"),
            runnerUp: ("ini soal perpisahan", "😢", "Haru", "#7B86C4"),
            extras: [("😮", "Takjub", "#C9A87C"), ("😌", "Tenang", "#1C1C1C")],
            winnerCount: 8
        ),
        entry(
            title: "Girl With Pearl Earring", artist: "Johannes Vermeer", year: "1665",
            museum: "Mauritshuis, Netherlands", likes: 172_200, aspect: 0.8,
            winner: ("kalau anting itu mutiara", "😮", "Takjub", "#B99B63"),
            runnerUp: ("dia baru saja menoleh", "😌", "Tenang", "#E4D5A8"),
            extras: [("🥰", "Hangat", "#7B86C4"), ("😢", "Haru", "#1C1C1C")],
            winnerCount: 7
        ),
        entry(
            title: "The Scream", artist: "Edvard Munch", year: "1893",
            museum: "The Munch, Norway", likes: 121_200, aspect: 0.86,
            winner: ("ini tentang kecemasan", "😢", "Haru", "#C4482A"),
            runnerUp: ("langitnya ikut berteriak", "😡", "Marah", "#E08A2E"),
            extras: [("😮", "Takjub", "#2A4A6E"), ("😌", "Tenang", "#3A3A5C")],
            winnerCount: 6
        ),
        entry(
            title: "The Great Wave", artist: "Katsushika Hokusai", year: "1831",
            museum: "Sumida Hokusai, Tokyo", likes: 172_200, aspect: 1.46,
            winner: ("ombaknya terasa hidup", "😮", "Takjub", "#1E4A6B"),
            runnerUp: ("ini terasa menenangkan", "😌", "Tenang", "#8CB4CE"),
            extras: [("🥰", "Hangat", "#E8DCC0"), ("😴", "Mengantuk", "#3A3A3A")],
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
