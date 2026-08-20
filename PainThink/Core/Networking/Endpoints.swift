//
//  Endpoints.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

enum Endpoint {
    static let baseURL = "https://discoverably-unlatticed-marylynn.ngrok-free.dev"
    static let paintingSearch = "\(baseURL)/api/v1/paintings/search"
    static let authLogin = "\(baseURL)/api/v1/auth/login"
    static let posts = "\(baseURL)/api/v1/posts"
    static let uploadImage = "\(baseURL)/api/v1/uploads/image"

    static func paintingQuestions(id: String) -> String {
        "\(baseURL)/api/v1/paintings/\(id)/questions"
    }

    static func paintingAnswers(id: String) -> String {
        "\(baseURL)/api/v1/paintings/\(id)/answers"
    }

    static func post(id: String) -> String {
        "\(baseURL)/api/v1/posts/\(id)"
    }

    static func userPosts(userID: String) -> String {
        "\(baseURL)/api/v1/users/\(userID)/posts"
    }
}
