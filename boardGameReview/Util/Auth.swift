//
//  Auth.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/18/26.
//

import Foundation


private let keychainRefreshTokenKey = "ludio_refresh_token"
private let defaultsUsernameKey     = "ludio_username"
private let defaultsUserIDKey       = "ludio_user_id"

final class Auth: ObservableObject {
    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var tokenType: String?
    @Published private(set) var username: String?
    @Published private(set) var userID: Int?

    /// Stashed invite token from a deep link, consumed after login/signup.
    @Published var pendingInviteToken: String?

    /// The refresh token stored in Keychain from the last session, if any.
    var storedRefreshToken: String? {
        KeychainHelper.load(key: keychainRefreshTokenKey)
    }

    func setSession(_ auth: AuthResponse) {
        accessToken  = auth.access_token
        print("Access Token: \(auth.access_token)")
        refreshToken = auth.refresh_token
        tokenType    = auth.token_type
        username     = auth.user.username
        userID       = auth.user.id

        KeychainHelper.save(auth.refresh_token, for: keychainRefreshTokenKey)
        UserDefaults.standard.set(auth.user.username, forKey: defaultsUsernameKey)
        UserDefaults.standard.set(auth.user.id,       forKey: defaultsUserIDKey)
    }

    func printUsername() {
        print(username ?? "No username set")
    }

    func clear() {
        accessToken  = nil
        refreshToken = nil
        tokenType    = nil
        username     = nil
        userID       = nil

        KeychainHelper.delete(key: keychainRefreshTokenKey)
        UserDefaults.standard.removeObject(forKey: defaultsUsernameKey)
        UserDefaults.standard.removeObject(forKey: defaultsUserIDKey)
    }
}

