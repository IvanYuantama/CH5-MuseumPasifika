//
//  AuthDTO.swift
//  PainThink
//

struct RegisterRequest: Encodable {
    let username: String
    let email: String?
    let password: String
}

struct LoginRequest: Encodable {
    let identifier: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: UserResponseDTO
}

struct UserResponseDTO: Decodable {
    let id: String
    let username: String
    let email: String
}

struct ExistsResponse: Decodable {
    let exists: Bool
}
