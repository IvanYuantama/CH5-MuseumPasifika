//
//  QuestionSetDTO.swift
//  PainThink
//

struct QuestionSetDTO: Decodable {
    let id: String
    let paintingID: String
    let questions: [QuestionDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case paintingID = "painting_id"
        case questions
    }
}

struct QuestionDTO: Decodable {
    let id: String
    let text: String
    let type: String
    let answers: [QuestionAnswerDTO]
}

struct QuestionAnswerDTO: Decodable {
    let label: String
    let value: String
}
