//
//  Painting.swift
//  PainThink
//

import Foundation

// A painting as the crowd sees it. Distinct from `PolaroidRecord`, which is one
// user's own capture: many polaroids from many visitors point at one Painting.
struct Painting: Identifiable, Hashable {
    let id: UUID
    let title: String
    let artist: String
    let year: String
    let museum: String
    let assetName: String?
    let likeCount: Int

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        year: String,
        museum: String,
        assetName: String? = nil,
        likeCount: Int = 0
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.year = year
        self.museum = museum
        self.assetName = assetName
        self.likeCount = likeCount
    }
}

// What one visitor left behind after finishing the develop activities: the
// statement they agreed with, plus the mood and colour they picked.
struct VisitorOpinion: Identifiable, Hashable {
    let id: UUID
    let statement: String
    let emoji: String
    let moodLabel: String
    let colorHex: String
    let visitorName: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        statement: String,
        emoji: String,
        moodLabel: String,
        colorHex: String,
        visitorName: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.statement = statement
        self.emoji = emoji
        self.moodLabel = moodLabel
        self.colorHex = colorHex
        self.visitorName = visitorName
        self.createdAt = createdAt
    }
}
