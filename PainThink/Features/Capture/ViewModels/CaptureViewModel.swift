//
//  CaptureViewModel.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import UIKit
import Observation

@Observable
final class CaptureViewModel {
    var capturedImage: UIImage?

    func reset() {
        capturedImage = nil
    }
}
