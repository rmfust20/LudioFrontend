//
//  UserService.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/18/26.
//

import Foundation

struct UserService {
    let client: APIClient
    let baseURL: String
    
    init(client: APIClient = APIClient.shared) {
        self.client = client
        //self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
        self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
    }
    
    func registerUser(user: UserModel) async throws -> RegisterResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/register"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        request.httpBody = data
        
        let (responseData, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        return try JSONDecoder().decode(RegisterResponse.self, from: responseData)
    }
    
    func login(username: String, password: String) async throws -> AuthResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/login"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let loginData = ["username": username, "password": password]
        let data = try encoder.encode(loginData)
        request.httpBody = data
        
        let (responseData, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        return try JSONDecoder().decode(AuthResponse.self, from: responseData)
    }
    
    func updateUser(updatedUser: UserProfileModel, accessToken: String) async throws -> UserProfileModel {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/updateUser"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(updatedUser)
        request.httpBody = data
        
        let (responseData, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let updated = try JSONDecoder().decode(UserProfileModel.self, from: responseData)
        return updated
    }
    
    func getUsers(userIDs: [Int], accessToken: String) async throws -> [UserProfileModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/userProfiles"
        components?.queryItems = userIDs.map { URLQueryItem(name: "user_ids", value: "\($0)") }
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        return try JSONDecoder().decode([UserProfileModel].self, from: data)
    }

    func getUser(userID: Int, accessToken: String) async throws -> UserProfileModel {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/userProfile/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let user = try JSONDecoder().decode(UserProfileModel.self, from: data)
        return user
    }
    
    func getUserFriendsPending(userID: Int, accessToken: String) async throws -> [UserPublicModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/pendingFriends/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let users = try JSONDecoder().decode([UserPublicModel].self, from: data)
        return users
    }
    
    func sendFriendRequest(userID: Int, friendID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/sendFriendRequest/\(userID)/\(friendID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "POST"
        
        let (_, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func removeFriend(userID: Int, friendID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/removeFriend/\(userID)/\(friendID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "DELETE"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    func acceptFriend(userID: Int, friendID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/acceptFriend/\(userID)/\(friendID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "POST"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    func rejectFriend(userID: Int, friendID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/rejectFriend/\(userID)/\(friendID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "POST"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    func getSentFriendRequests(userID: Int, accessToken: String) async throws -> [UserPublicModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/sentFriendRequests/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode([UserPublicModel].self, from: data)
    }

    func searchUsers(username: String, accessToken: String) async throws -> [UserPublicModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/search"
        components?.queryItems = [URLQueryItem(name: "username", value: username)]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode([UserPublicModel].self, from: data)
    }

    func logout(refreshToken: String, accessToken:String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/logout"
        components?.queryItems = [URLQueryItem(name: "refresh_token", value: refreshToken)]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "POST"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func deleteAccount(accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/deleteAccount"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        request.httpMethod = "DELETE"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func getWinRate(userID: Int, accessToken:String) async throws -> WinRateResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/winRate/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(WinRateResponse.self, from: data)
    }

    func refresh(refreshToken: String) async throws -> RefreshTokenResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/refresh"
        components?.queryItems = [URLQueryItem(name: "refresh_token", value: refreshToken)]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let (data, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
    }

    func appleSignIn(identityToken: String) async throws -> AppleAuthResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/auth/apple"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["identity_token": identityToken])

        let (data, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(AppleAuthResponse.self, from: data)
    }

    func appleCompleteRegistration(appleID: String, username: String, email: String?) async throws -> AuthResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/auth/apple/complete"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = AppleCompleteRequest(apple_id: appleID, username: username, email: email)
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func forgotPassword(email: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/forgotPassword"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email])

        let (_, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func resetPassword(token: String, newPassword: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/resetPassword"
        guard let url = components?.url else { throw APIError.invalidURL }

        struct Body: Encodable { let token: String; let new_password: String }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(Body(token: token, new_password: newPassword))

        let (_, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func generateInvite(accessToken: String) async throws -> InviteResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/invite"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "POST"

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(InviteResponse.self, from: data)
    }

    func acceptInvite(token: String, accessToken: String) async throws -> AcceptInviteResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/invite/accept"
        components?.queryItems = [URLQueryItem(name: "token", value: token)]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        request.httpMethod = "POST"

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(AcceptInviteResponse.self, from: data)
    }

    func getWinRateForGame(userID: Int, boardGameID: Int, accessToken: String) async throws -> WinRateResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/winRate/\(userID)/\(boardGameID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(WinRateResponse.self, from: data)
    }

}
