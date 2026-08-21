//
//  APIClient.swift
//  PainThink
//
//  Created by Ivan Yuantama Pradipta on 06/08/26.
//

import UIKit

final class APIClient {
    static let shared = APIClient()
    private init() {}

    func fetchPainting(byTitle title: String) async throws -> PaintingDTO {
        guard var components = URLComponents(string: Endpoint.paintingSearch) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "title", value: title)]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }

        if httpResponse.statusCode == 404 {
            throw NetworkError.notFound
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }

        let envelope = try JSONDecoder().decode(APIEnvelope<PaintingDTO>.self, from: data)
        guard let painting = envelope.data else {
            throw NetworkError.notFound
        }
        return painting
    }

    func fetchQuestions(paintingID: String) async throws -> QuestionSetDTO {
        guard let url = URL(string: Endpoint.paintingQuestions(id: paintingID)) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }

        if httpResponse.statusCode == 404 {
            throw NetworkError.notFound
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }

        let envelope = try JSONDecoder().decode(APIEnvelope<QuestionSetDTO>.self, from: data)
        guard let questionSet = envelope.data else {
            throw NetworkError.notFound
        }
        return questionSet
    }

    func generateAccount() async throws -> AuthResponse {
        guard let url = URL(string: Endpoint.authGenerateAccount) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<AuthResponse>.self, from: data)
        guard let auth = envelope.data else {
            throw NetworkError.serverError
        }
        return auth
    }

    func register(username: String, email: String? = nil, password: String) async throws -> AuthResponse {
        guard let url = URL(string: Endpoint.authRegister) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RegisterRequest(username: username, email: email, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<AuthResponse>.self, from: data)
        guard let auth = envelope.data else {
            throw NetworkError.serverError
        }
        return auth
    }

    func login(identifier: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: Endpoint.authLogin) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(LoginRequest(identifier: identifier, password: password))

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<AuthResponse>.self, from: data)
        guard let auth = envelope.data else {
            throw NetworkError.serverError
        }
        return auth
    }

    func checkUserExists(identifier: String) async throws -> Bool {
        guard var components = URLComponents(string: Endpoint.authExists) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "identifier", value: identifier)]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<ExistsResponse>.self, from: data)
        return envelope.data?.exists ?? false
    }

    func getCurrentUser() async throws -> UserResponseDTO {
        guard let url = URL(string: Endpoint.usersMe) else {
            throw NetworkError.invalidURL
        }

        let request = try await Self.authorizedRequest(url: url, method: "GET")
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<UserResponseDTO>.self, from: data)
        guard let user = envelope.data else {
            throw NetworkError.notFound
        }
        return user
    }

    func uploadImage(_ image: UIImage) async throws -> String {
        guard let url = URL(string: Endpoint.uploadImage) else {
            throw NetworkError.invalidURL
        }
        guard let jpegData = image.jpegData(compressionQuality: 0.85) else {
            throw NetworkError.invalidImage
        }

        let token = try await SessionManager.shared.token()
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = Self.multipartBody(fieldName: "image", filename: "photo.jpg", mimeType: "image/jpeg", fileData: jpegData, boundary: boundary)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<UploadResponse>.self, from: data)
        guard let uploaded = envelope.data else {
            throw NetworkError.serverError
        }
        return uploaded.url
    }

    func fetchPosts(page: Int = 1, limit: Int = 20) async throws -> [PostResponseDTO] {
        guard var components = URLComponents(string: Endpoint.posts) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<[PostResponseDTO]>.self, from: data)
        return envelope.data ?? []
    }

    func fetchPost(id: String) async throws -> PostResponseDTO {
        guard let url = URL(string: Endpoint.post(id: id)) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<PostResponseDTO>.self, from: data)
        guard let post = envelope.data else {
            throw NetworkError.notFound
        }
        return post
    }

    func createPost(_ req: CreatePostRequest) async throws {
        guard let url = URL(string: Endpoint.posts) else {
            throw NetworkError.invalidURL
        }

        var request = try await Self.authorizedRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(req)

        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    func updatePost(id: String, _ req: UpdatePostRequest) async throws {
        guard let url = URL(string: Endpoint.post(id: id)) else {
            throw NetworkError.invalidURL
        }

        var request = try await Self.authorizedRequest(url: url, method: "PUT")
        request.httpBody = try JSONEncoder().encode(req)

        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    func fetchUserPosts(userID: String, limit: Int = 100) async throws -> [PostResponseDTO] {
        guard var components = URLComponents(string: Endpoint.userPosts(userID: userID)) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [URLQueryItem(name: "limit", value: String(limit))]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<[PostResponseDTO]>.self, from: data)
        return envelope.data ?? []
    }

    func deletePost(id: String) async throws {
        guard let url = URL(string: Endpoint.post(id: id)) else {
            throw NetworkError.invalidURL
        }

        let request = try await Self.authorizedRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    func fetchPaintings(page: Int = 1, limit: Int = 20) async throws -> [PaintingDTO] {
        guard var components = URLComponents(string: Endpoint.paintings) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<[PaintingDTO]>.self, from: data)
        return envelope.data ?? []
    }

    func fetchPainting(byID id: String) async throws -> PaintingDTO {
        guard let url = URL(string: Endpoint.painting(id: id)) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<PaintingDTO>.self, from: data)
        guard let painting = envelope.data else {
            throw NetworkError.notFound
        }
        return painting
    }

    func createPainting(_ req: CreatePaintingRequest) async throws -> PaintingDTO {
        guard let url = URL(string: Endpoint.paintings) else {
            throw NetworkError.invalidURL
        }

        var request = try await Self.authorizedRequest(url: url, method: "POST")
        request.httpBody = try JSONEncoder().encode(req)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<PaintingDTO>.self, from: data)
        guard let painting = envelope.data else {
            throw NetworkError.serverError
        }
        return painting
    }

    func updatePainting(id: String, _ req: UpdatePaintingRequest) async throws -> PaintingDTO {
        guard let url = URL(string: Endpoint.painting(id: id)) else {
            throw NetworkError.invalidURL
        }

        var request = try await Self.authorizedRequest(url: url, method: "PUT")
        request.httpBody = try JSONEncoder().encode(req)

        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)

        let envelope = try JSONDecoder().decode(APIEnvelope<PaintingDTO>.self, from: data)
        guard let painting = envelope.data else {
            throw NetworkError.serverError
        }
        return painting
    }

    func deletePainting(id: String) async throws {
        guard let url = URL(string: Endpoint.painting(id: id)) else {
            throw NetworkError.invalidURL
        }

        let request = try await Self.authorizedRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    func submitAnswers(paintingID: String, answers: [SubmitAnswerRequest]) async throws {
        guard let url = URL(string: Endpoint.paintingAnswers(id: paintingID)) else {
            throw NetworkError.invalidURL
        }

        var request = try await Self.authorizedRequest(url: url, method: "PUT")
        request.httpBody = try JSONEncoder().encode(SubmitAnswersRequest(answers: answers))

        let (_, response) = try await URLSession.shared.data(for: request)
        try Self.validate(response)
    }

    private static func authorizedRequest(url: URL, method: String) async throws -> URLRequest {
        let token = try await SessionManager.shared.token()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("true", forHTTPHeaderField: "ngrok-skip-browser-warning")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    private static func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError
        }
        if httpResponse.statusCode == 404 {
            throw NetworkError.notFound
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }
    }

    private static func multipartBody(fieldName: String, filename: String, mimeType: String, fileData: Data, boundary: String) -> Data {
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        return body
    }
}

enum NetworkError: Error {
    case invalidImage
    case invalidURL
    case serverError
    case notFound
}
