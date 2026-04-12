//
//  APIResponse.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/6/25.
//

import Foundation

struct APIResponse: Codable {
    let AuthResponse: AuthResponse
    let RegisterResponse: RegisterResponse
}

struct AuthResponse: Codable {
    let access_token: String
    let refresh_token: String
    let token_type: String
    let user: RegisterResponse
}

struct RegisterResponse: Codable {
    let username: String
    let id : Int
}

struct WinRateResponse: Codable {
    let user_id: Int
    let wins: Int
    let total_sessions: Int
    let win_rate: Double
    let board_game_id: Int?
}

// Token refresh (no user object returned by /users/refresh)
struct RefreshTokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let token_type: String
}

// Apple Sign In
struct AppleAuthResponse: Codable {
    // Returned when the Apple ID is already linked to an account
    let access_token: String?
    let refresh_token: String?
    let token_type: String?
    let user: RegisterResponse?
    // Returned when this is a new Apple user who still needs a username
    let needs_username: Bool?
    let apple_id: String?
    let email: String?
}

struct AppleCompleteRequest: Codable {
    let apple_id: String
    let username: String
    let email: String?
}

struct InviteResponse: Codable {
    let token: String
    let expires_in_days: Int
}

struct AcceptInviteResponse: Codable {
    let message: String
    let inviter_id: Int
}
