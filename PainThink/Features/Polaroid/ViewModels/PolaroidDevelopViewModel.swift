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

    private var record: PolaroidRecord?

    init(image: UIImage) {
        self.image = image
        self.activities = ActivityGenerator.generateActivities(for: image)
    }

    var completedCount: Int { answers.count }
    var isUnlocked: Bool { completedCount >= activities.count }

    func start(context: ModelContext) async {
        guard record == nil else { return }

        let data = image.jpegData(compressionQuality: 0.85) ?? Data()
        let newRecord = PolaroidRecord(imageData: data, totalActivities: activities.count)
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
