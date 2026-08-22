//
//  Endpoints.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

enum Endpoint {
    static let baseURL = "https://painthink.ryansafa.cloud"

    // Health
    static let health = "\(baseURL)/health"

    // Auth
    static let authRegister = "\(baseURL)/api/v1/auth/register"
    static let authLogin = "\(baseURL)/api/v1/auth/login"
    static let authExists = "\(baseURL)/api/v1/auth/exists"
    static let authGenerateAccount = "\(baseURL)/api/v1/auth/generate-account"

    // Users
    static let usersMe = "\(baseURL)/api/v1/users/me"

    // Posts
    static let posts = "\(baseURL)/api/v1/posts"

    // Paintings
    static let paintings = "\(baseURL)/api/v1/paintings"
    static let paintingSearch = "\(baseURL)/api/v1/paintings/search"

    // Uploads
    static let uploadImage = "\(baseURL)/api/v1/uploads/image"

    static func painting(id: String) -> String {
        "\(baseURL)/api/v1/paintings/\(id)"
    }

    static func paintingQuestions(id: String) -> String {
        "\(baseURL)/api/v1/paintings/\(id)/questions"
    }

    static func paintingAnswers(id: String) -> String {
        "\(baseURL)/api/v1/paintings/\(id)/answers"
    }

    static func paintingAllAnswers(id: String) -> String {
        "\(baseURL)/api/v1/paintings/\(id)/answers/all"
    }

    static func post(id: String) -> String {
        "\(baseURL)/api/v1/posts/\(id)"
    }

    static func userPosts(userID: String) -> String {
        "\(baseURL)/api/v1/users/\(userID)/posts"
    }
}
