//
//  PostDTO.swift
//  PainThink
//

struct QuestionAnswerPair: Codable, Hashable {
    let question: String
    let answer: String
}

// UserID is deliberately absent: the owning user is always taken from the
// authenticated request, never sent by the client.
struct CreatePostRequest: Encodable {
    let title: String
    let image: String
    let questions: [QuestionAnswerPair]
    let location: String
}

struct UpdatePostRequest: Encodable {
    let title: String?
    let image: String?
    let questions: [QuestionAnswerPair]?
    let location: String?
}

struct PostResponseDTO: Decodable {
    let id: String
    let userID: String
    let title: String
    let image: String
    // Nullable: a post created with an empty question list can round-trip
    // as JSON `null` rather than `[]`.
    let questions: [QuestionAnswerPair]?
    let location: String

    enum CodingKeys: String, CodingKey {
        case id, title, image, questions, location
        case userID = "user_id"
    }
}
