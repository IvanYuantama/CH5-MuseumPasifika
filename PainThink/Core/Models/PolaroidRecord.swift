//
//  PolaroidRecord.swift
//  PainThink
//

import Foundation
import SwiftData

@Model
final class PolaroidRecord {
    @Attribute(.unique) var id: UUID
    var imageData: Data
    var createdAt: Date
    var detectedLabel: String?
    var confidence: Double?
    var paintingTitle: String?
    var artistName: String?
    var location: String?
    var totalActivities: Int
    var completedActivityCount: Int
    var isUnlocked: Bool

    init(imageData: Data, totalActivities: Int) {
        self.id = UUID()
        self.imageData = imageData
        self.createdAt = Date()
        self.detectedLabel = nil
        self.confidence = nil
        self.paintingTitle = nil
        self.artistName = nil
        self.location = nil
        self.totalActivities = totalActivities
        self.completedActivityCount = 0
        self.isUnlocked = false
    }
}
