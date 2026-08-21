//
//  SessionManager.swift
//  PainThink
//

// Anonymous per-device account: on first launch, generate-account mints a
// UUID-username account with an empty password and stores the username in
// Keychain so it survives app reinstalls.
// Subsequent launches log back in with that same username + empty password.
import Security
import Foundation

actor SessionManager {
    static let shared = SessionManager()
    private init() {}

    private let usernameKey = "painthink.generated_username"

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
            if let username = self.loadUsername() {
                return try await APIClient.shared.login(identifier: username, password: "")
            }
            let result = try await APIClient.shared.generateAccount()
            self.saveUsername(result.user.username)
            return result
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

    private func saveUsername(_ username: String) {
        guard let data = username.data(using: .utf8) else { return }
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: usernameKey,
            kSecValueData: data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    private func loadUsername() -> String? {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: usernameKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
