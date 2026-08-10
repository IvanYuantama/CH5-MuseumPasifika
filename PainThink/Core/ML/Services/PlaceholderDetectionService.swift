//
//  PlaceholderDetectionService.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import CoreVideo

/// Dipakai SEBELUM model .mlpackage tersedia. Tidak mendeteksi apapun,
/// tapi bikin seluruh pipeline (kamera -> overlay -> UI) tetap bisa dites end-to-end.
final class PlaceholderDetectionService: ArtworkDetectionServicing {
    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void) {
        completion([])
    }
}
