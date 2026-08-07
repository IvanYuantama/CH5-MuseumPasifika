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

    func detectPaint(image: UIImage) async throws -> DetectPaintResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidImage
        }

        guard let url = URL(string: Endpoint.detectPaint) else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"capture.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError
        }

        return try JSONDecoder().decode(DetectPaintResponse.self, from: data)
    }
}

enum NetworkError: Error {
    case invalidImage
    case invalidURL
    case serverError
}
