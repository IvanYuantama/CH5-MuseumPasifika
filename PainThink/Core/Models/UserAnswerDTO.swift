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
