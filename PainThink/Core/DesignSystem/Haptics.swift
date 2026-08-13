//
//  Haptics.swift
//  PainThink
//

import UIKit

// One place for feedback so every answer interaction feels the same:
// `tap` for picking/picking-up, `success` for landing an answer.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
