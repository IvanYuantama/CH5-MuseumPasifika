//
//  PolaroidDevelopViewModel.swift
//  PainThink
//

import UIKit
import SwiftData
import Observation

@Observable
final class PolaroidDevelopViewModel {
    private static let confidenceThreshold = 0.7

    let image: UIImage
    let activities: [Activity]
    var answers: [UUID: String] = [:]
    var detectedLabel: String?
    var isDetecting = false

    var paintingTitle = "Detecting…"
    var artistName = ""
    var year = ""
    var location = MuseumInfo.currentName
    let captureDate: String

    // Set once classification + backend lookup finish, real or fallback.
    // Feeds PaintingDetailView once the user asks to see what others thought.
    private(set) var resolvedPainting: Painting?

    private var record: PolaroidRecord?
    private let classifier = PaintingClassifierService()

    init(image: UIImage) {
        self.image = image
        self.activities = ActivityGenerator.generateActivities(for: image)

        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy"
        formatter.locale = Locale(identifier: "en_US")
        self.captureDate = formatter.string(from: Date())
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
        await resolvePainting(into: newRecord)
        isDetecting = false
    }

    private func resolvePainting(into record: PolaroidRecord) async {
        do {
            let (label, confidence) = try await classifier.classify(image)
            detectedLabel = label
            record.detectedLabel = label
            record.confidence = confidence

            guard confidence >= Self.confidenceThreshold else {
                applyFallback(into: record)
                return
            }

            let dto = try await APIClient.shared.fetchPainting(byTitle: label)
            apply(dto, into: record)
        } catch {
            // Classifier failure, or no matching painting on the backend yet.
            applyFallback(into: record)
        }
    }

    private func apply(_ dto: PaintingDTO, into record: PolaroidRecord) {
        paintingTitle = dto.title
        artistName = dto.artist
        year = dto.year

        record.paintingTitle = dto.title
        record.artistName = dto.artist
        record.location = location

        resolvedPainting = Painting(
            title: dto.title,
            artist: dto.artist,
            year: dto.year,
            museum: location,
            imageURLString: dto.image
        )
    }

    private func applyFallback(into record: PolaroidRecord) {
        paintingTitle = "Untitled"
        artistName = "Unknown Artist"
        year = "Undated"
        location = MuseumInfo.currentName

        record.paintingTitle = paintingTitle
        record.artistName = artistName
        record.location = location

        resolvedPainting = Painting(
            title: paintingTitle,
            artist: artistName,
            year: year,
            museum: location
        )
    }

    func select(_ moodLabel: String, for activity: Activity) {
        answers[activity.id] = moodLabel
        record?.completedActivityCount = completedCount
        if isUnlocked {
            record?.isUnlocked = true
        }
    }
}
