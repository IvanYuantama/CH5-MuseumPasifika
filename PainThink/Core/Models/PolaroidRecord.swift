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
    var totalActivities: Int
    var completedActivityCount: Int
    var isUnlocked: Bool

    init(imageData: Data, totalActivities: Int) {
        self.id = UUID()
        self.imageData = imageData
        self.createdAt = Date()
        self.detectedLabel = nil
        self.confidence = nil
        self.totalActivities = totalActivities
        self.completedActivityCount = 0
        self.isUnlocked = false
    }
}
