//
//  PolaroidDevelopViewModel.swift
//  PainThink
//

import UIKit
import SwiftData
import Observation

@Observable
final class PolaroidDevelopViewModel {
    let image: UIImage
    let activities: [Activity]
    var answers: [UUID: String] = [:]
    var detectedLabel: String?
    var isDetecting = false

    // Placeholder painting info until the backend can return real metadata per detection.
    let paintingTitle = "Girl With Pearl Earring"
    let artistName = "Johannes Vermeer"
    let year = "1665"
    let location = "Mauritshuis, Netherlands"
    let captureDate: String

    private var record: PolaroidRecord?

    init(image: UIImage) {
        self.image = image
        self.activities = ActivityGenerator.generateActivities(for: image)

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "id_ID")
        self.captureDate = formatter.string(from: Date())
    }

    var completedCount: Int { answers.count }
    var isUnlocked: Bool { completedCount >= activities.count }

    func start(context: ModelContext) async {
        guard record == nil else { return }

        let data = image.jpegData(compressionQuality: 0.85) ?? Data()
        let newRecord = PolaroidRecord(imageData: data, totalActivities: activities.count)
        newRecord.paintingTitle = paintingTitle
        newRecord.artistName = artistName
        newRecord.location = location
        context.insert(newRecord)
        record = newRecord

        isDetecting = true
        do {
            let result = try await APIClient.shared.detectPaint(image: image)
            newRecord.confidence = result.confidence
            if result.detected {
                detectedLabel = "Lukisan terdeteksi"
                newRecord.detectedLabel = detectedLabel
            }
        } catch {
            // Best-effort: detection failure shouldn't block the activities.
        }
        isDetecting = false
    }

    func select(_ moodLabel: String, for activity: Activity) {
        answers[activity.id] = moodLabel
        record?.completedActivityCount = completedCount
        if isUnlocked {
            record?.isUnlocked = true
        }
    }
}
