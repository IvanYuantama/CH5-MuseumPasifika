//
//  AuthDTO.swift
//  PainThink
//

struct LoginRequest: Encodable {
    let email: String
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
