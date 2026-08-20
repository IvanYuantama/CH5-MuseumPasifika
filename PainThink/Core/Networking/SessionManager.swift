//
//  SessionManager.swift
//  PainThink
//

// The app has no login UI yet — every submission is attributed to this
// single default account. Replace with real per-user auth once that lands.
actor SessionManager {
    static let shared = SessionManager()

    private let email = "wayanrizkywijaya@gmail.com"
    private let password = "userkiki"

    private var cached: AuthResponse?
    private var loginTask: Task<AuthResponse, Error>?

    func token() async throws -> String {
        try await auth().token
    }

    func userID() async throws -> String {
        try await auth().user.id
    }

    private func auth() async throws -> AuthResponse {
        if let cached { return cached }

        if let loginTask {
            return try await loginTask.value
        }

        let task = Task<AuthResponse, Error> {
            try await APIClient.shared.login(email: email, password: password)
        }
        loginTask = task

        do {
            let result = try await task.value
            cached = result
            loginTask = nil
            return result
        } catch {
            loginTask = nil
            throw error
        }
    }
}
