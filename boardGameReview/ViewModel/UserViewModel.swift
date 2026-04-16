//
//  UserViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/18/26.
//

import Foundation

enum AppleSignInResult {
    case success
    case needsUsername(appleID: String, email: String?)
    case failed
}

enum RegisterResult {
    case success
    case duplicate
    case failed
}

class UserViewModel: ObservableObject {
    var userService = UserService()
    
    func register(username: String, email: String, password: String, authStore: Auth) async -> RegisterResult {
        let user = UserModel(id: nil, username: username, email: email, password: password, profile_image_url: nil)
        do {
            _ = try await userService.registerUser(user: user)
        } catch APIError.httpStatus(let code) where code == 400 || code == 409 {
            return .duplicate
        } catch {
            return .failed
        }

        guard let accessResponse = try? await userService.login(username: username, password: password) else {
            return .failed
        }
        await populateAuth(auth: accessResponse, authStore: authStore)
        return .success
    }
    
    func login(username: String, password: String, authStore: Auth) async {
        let accessResponse = try? await userService.login(username: username, password: password)
        if let accessResponse = accessResponse {
            await populateAuth(auth: accessResponse, authStore: authStore)
        }
    }
    
    func appleSignIn(identityToken: String, authStore: Auth) async -> AppleSignInResult {
        guard let response = try? await userService.appleSignIn(identityToken: identityToken) else {
            return .failed
        }

        if let accessToken = response.access_token,
           let refreshToken = response.refresh_token,
           let tokenType = response.token_type,
           let user = response.user {
            await populateAuth(
                auth: AuthResponse(
                    access_token: accessToken,
                    refresh_token: refreshToken,
                    token_type: tokenType,
                    user: user
                ),
                authStore: authStore
            )
            return .success
        }

        if response.needs_username == true, let appleID = response.apple_id {
            return .needsUsername(appleID: appleID, email: response.email)
        }

        return .failed
    }

    func appleCompleteRegistration(appleID: String, username: String, email: String?, authStore: Auth) async -> Bool {
        guard let auth = try? await userService.appleCompleteRegistration(appleID: appleID, username: username, email: email) else {
            return false
        }
        await populateAuth(auth: auth, authStore: authStore)
        return true
    }

    func forgotPassword(email: String) async -> Bool {
        (try? await userService.forgotPassword(email: email)) != nil
    }

    func resetPassword(token: String, newPassword: String) async -> Bool {
        (try? await userService.resetPassword(token: token, newPassword: newPassword)) != nil
    }

    @MainActor
    func populateAuth(auth: AuthResponse, authStore: Auth) {
        authStore.setSession(auth)
    }


}
