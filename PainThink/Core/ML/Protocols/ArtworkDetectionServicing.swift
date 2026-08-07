//
//  ArtworkDetectionServicing.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import CoreVideo

protocol ArtworkDetectionServicing {
    func detect(in pixelBuffer: CVPixelBuffer, completion: @escaping ([DetectedObject]) -> Void)
}
