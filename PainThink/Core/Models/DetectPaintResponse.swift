//
//  DetectPaintResponse.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

struct DetectPaintResponse: Decodable {
    let detected: Bool
    let confidence: Double
    let boundingBox: BoundingBox?

    enum CodingKeys: String, CodingKey {
        case detected
        case confidence
        case boundingBox = "bounding_box"
    }
}

struct BoundingBox: Decodable {
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
