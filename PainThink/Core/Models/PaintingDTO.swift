//
//  PaintingDTO.swift
//  PainThink
//

struct APIEnvelope<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct PaintingDTO: Decodable {
    let id: String
    let title: String
    let artist: String
    let image: String
    let description: String
    let year: String
}

struct CreatePaintingRequest: Encodable {
    let title: String
    let artist: String
    let image: String
    let description: String?
    let year: String?
}

struct UpdatePaintingRequest: Encodable {
    let title: String?
    let artist: String?
    let image: String?
    let description: String?
    let year: String?
}
