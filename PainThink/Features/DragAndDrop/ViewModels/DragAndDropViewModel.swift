//
//  DragAndDropViewModel.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 11/08/26.
//

import UIKit
import Observation

@Observable
final class DragAndDropViewModel {
    // MARK: - Painting Info (Dummy Data)
    var paintingImage: UIImage?
    var paintingTitle: String = "Girl With Pearl Earring"
    var artistName: String = "Johannes Veermer"
    var year: String = "1665"
    var location: String = "Mauritshuis, Netherlands"
    var captureDate: String = "8 August 2026"

    // MARK: - Question (Dummy)
    var question: String = "What is the person wearing in the ear?"
    var answer: String = ""

    // MARK: - Mood
    var moodOptions: [String] = ["Sad", "Happy", "Neutral"]
    var selectedMoods: Set<String> = []

    // MARK: - Additional Notes
    var additionalNotes: [String] = []

    init(paintingImage: UIImage? = nil) {
        self.paintingImage = paintingImage
    }

    func toggleMood(_ mood: String) {
        if selectedMoods.contains(mood) {
            selectedMoods.remove(mood)
        } else {
            selectedMoods.insert(mood)
        }
    }

    func addNote() {
        additionalNotes.append("")
    }
}
