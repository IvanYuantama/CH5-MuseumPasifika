//
//  PolaroidDevelopViewModel.swift
//  PainThink
//

import UIKit
import SwiftData
import Observation

@Observable
final class PolaroidDevelopViewModel {
    private static let confidenceThreshold = 0.95

    let image: UIImage
    private(set) var activities: [Activity]
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

    // Set once a real backend painting match is confirmed; nil for the
    // "Untitled" fallback, since there's no painting to attach answers/dedupe
    // a post against.
    private var matchedPaintingID: String?
    // True only once `applyQuestions` swapped in the painting's real question
    // set — only then do `activities` carry backend `questionID`s we can
    // submit answers against.
    private var isUsingBackendQuestions = false
    private var didSubmitResults = false

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
            await applyQuestions(forPaintingID: dto.id)
        } catch {
            // Classifier failure, or no matching painting on the backend yet.
            applyFallback(into: record)
        }
    }

    private func apply(_ dto: PaintingDTO, into record: PolaroidRecord) {
        paintingTitle = dto.title
        artistName = dto.artist
        year = dto.year
        matchedPaintingID = dto.id

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

    // Swaps in the matched painting's real questions. Left untouched (still
    // the local hardcoded set from init) if the painting has none yet, or if
    // the user already started answering the locally-generated set.
    private func applyQuestions(forPaintingID paintingID: String) async {
        guard answers.isEmpty else { return }
        guard let questionSet = try? await APIClient.shared.fetchQuestions(paintingID: paintingID) else { return }

        let matched = ActivityGenerator.makeActivities(from: questionSet.questions, image: image)
        guard !matched.isEmpty else { return }
        activities = matched
        record?.totalActivities = matched.count
        isUsingBackendQuestions = true
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
            if !didSubmitResults {
                didSubmitResults = true
                Task { await submitResults() }
            }
        }
    }

    // Fires once, when the last activity is answered: uploads the photo,
    // creates/updates this painting's post, and (when the questions came
    // from the backend) submits the structured answer set. Best-effort —
    // failures are swallowed since there's no error UI for this background
    // sync today.
    private func submitResults() async {
        guard let imageURL = try? await APIClient.shared.uploadImage(image) else { return }

        await createOrUpdatePost(imageURL: imageURL)

        if isUsingBackendQuestions, let paintingID = matchedPaintingID {
            await submitAnswersToBackend(paintingID: paintingID)
        }
    }

    private func submitAnswersToBackend(paintingID: String) async {
        let payload = activities.compactMap { activity -> SubmitAnswerRequest? in
            guard let questionID = activity.questionID, let value = answerValue(for: activity) else { return nil }
            return SubmitAnswerRequest(questionID: questionID, value: value)
        }
        guard !payload.isEmpty else { return }
        try? await APIClient.shared.submitAnswers(paintingID: paintingID, answers: payload)
    }

    private func createOrUpdatePost(imageURL: String) async {
        let questions = activities.map { activity in
            QuestionAnswerPair(question: activity.prompt, answer: answerValue(for: activity) ?? "")
        }

        do {
            let userID = try await SessionManager.shared.userID()

            var existingPostID: String?
            if matchedPaintingID != nil {
                let posts = try await APIClient.shared.fetchUserPosts(userID: userID)
                existingPostID = posts.first(where: { $0.title == paintingTitle })?.id
            }

            if let existingPostID {
                try await APIClient.shared.updatePost(
                    id: existingPostID,
                    UpdatePostRequest(title: paintingTitle, image: imageURL, questions: questions, location: location)
                )
            } else {
                try await APIClient.shared.createPost(
                    CreatePostRequest(title: paintingTitle, image: imageURL, questions: questions, location: location)
                )
            }
        } catch {
            return
        }
    }

    // The color activity's stored answer is a mood label (for UI highlight
    // matching); the backend wants the hex of the color the user actually
    // picked, so it's resolved from the matching palette option here.
    private func answerValue(for activity: Activity) -> String? {
        guard let label = answers[activity.id] else { return nil }
        guard activity.kind == .colorPaletteMood else { return label }
        guard let color = activity.paletteOptions.first(where: { $0.moodLabel == label })?.color else { return label }
        return color.hexString
    }
}
