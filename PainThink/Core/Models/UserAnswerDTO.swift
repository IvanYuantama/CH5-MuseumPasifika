//
//  UserAnswerDTO.swift
//  PainThink
//

struct SubmitAnswerRequest: Encodable {
    let questionID: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case value
    }
}

struct SubmitAnswersRequest: Encodable {
    let answers: [SubmitAnswerRequest]
}

struct SubmittedAnswerResponseDTO: Decodable {
    let questionID: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case questionID = "question_id"
        case value
    }
}

// One user's full answer set for one painting — the shape returned by both
// `GET /paintings/:id/answers` (mine only) and `GET /paintings/:id/answers/all`
// (everyone's, used to build painting-wide statistics).
struct UserAnswerSetResponseDTO: Decodable {
    let id: String
    let userID: String
    let paintingID: String
    let answers: [SubmittedAnswerResponseDTO]

    enum CodingKeys: String, CodingKey {
        case id, answers
        case userID = "user_id"
        case paintingID = "painting_id"
    }
}
