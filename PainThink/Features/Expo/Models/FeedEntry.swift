//
//  FeedEntry.swift
//  PainThink
//

import Foundation

// One tile in the expo feed: a painting plus the opinions attached to it.
// Carries `aspectRatio` because the staggered layout needs to know how tall a
// tile will be before the artwork itself has loaded.
struct FeedEntry: Identifiable, Hashable {
    var id: UUID { painting.id }

    let painting: Painting
    let opinions: [VisitorOpinion]
    let aspectRatio: CGFloat
    // The signed-in user's own quiz answers for this exact post, straight from
    // `PostResponseDTO.questions`. Empty for entries built from sample data
    // (Expo feed) — only Collection cards populate this.
    let userAnswers: [QuestionAnswerPair]

    init(
        painting: Painting,
        opinions: [VisitorOpinion],
        aspectRatio: CGFloat = 0.78,
        userAnswers: [QuestionAnswerPair] = []
    ) {
        self.painting = painting
        self.opinions = opinions
        self.aspectRatio = aspectRatio
        self.userAnswers = userAnswers
    }
}
