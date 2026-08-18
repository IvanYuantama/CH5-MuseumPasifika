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
}

enum NetworkError: Error {
    case invalidImage
    case invalidURL
    case serverError
    case notFound
}
