//
//  DetectedObject.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import Foundation
import CoreGraphics

struct DetectedObject: Identifiable, Equatable {
    let id = UUID()
    let label: String
    let confidence: Float
    let boundingBox: CGRect
}
