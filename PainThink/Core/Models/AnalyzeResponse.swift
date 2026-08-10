//
//  AnalyzeResponse.swift
//  PainThink
//

struct AnalyzeResponse: Decodable {
    let shortDescription: String
    let detailedAnalysis: String
    let openingQuestion: String
}
