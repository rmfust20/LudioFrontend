//
//  GameNightService.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/26/26.
//

import Foundation

struct GameNightService {
    let client: APIClient
    let baseURL: String

    init(client: APIClient = APIClient.shared) {
        self.client = client
        self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
    }
    
    func getUserFriends(userID: Int, accessToken: String) async throws -> [UserPublicModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/friends/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let friends = try JSONDecoder().decode([UserPublicModel].self, from: data)
    
        return friends
    }
    
    func postGameNight(gameNight: GameNightUploadModel, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/postNight"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(gameNight)
        request.httpBody = data
        
        let (_, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    func getGameNightFeed(userID: Int, offset: Int = 0, limit: Int = 10, accessToken: String) async throws -> [GameNightModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/userFeed/\(userID)"
        components?.queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components?.url else { throw APIError.invalidURL }
        

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        do {
            let gameNights = try JSONDecoder().decode([GameNightModel].self, from: data)
            return gameNights
        } catch {
            throw error
        }
    }
    
    func getUserBoardGames(userID: Int, accessToken: String) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/boardGames/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let userBoardGames = try JSONDecoder().decode([BoardGameModel].self, from: data)
        return userBoardGames
    }
    
    func getGameNight(id: Int, accessToken: String) async throws -> GameNightModel {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/\(id)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(GameNightModel.self, from: data)
    }

    func getUserGameNights(userID: Int, offset: Int = 0, limit: Int = 10, accessToken: String) async throws -> [GameNightModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/userGameNights/\(userID)"
        components?.queryItems = [
            URLQueryItem(name: "offset", value: "\(offset)"),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        let userGameNights = try JSONDecoder().decode([GameNightModel].self, from: data)
        return userGameNights
    }
    
    func getRecentGameNightsWithImages(userID: Int, accessToken: String) async throws -> [GameNightModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/recentWithImages/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode([GameNightModel].self, from: data)
    }

    func reportGameNight(gameNightID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/reportGameNight/\(gameNightID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        request.httpMethod = "POST"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func deleteGameNight(gameNightID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/\(gameNightID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        request.httpMethod = "DELETE"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    
    
    
}
