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
    
    func getUserFriends(userID: Int) async throws -> [UserPublicModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/friends/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        //try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.getSession().data(for: request)
        
        

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
        
        let (responseData, response) = try await client.getSession().data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    func getGameNightFeed(userID : Int) async throws -> [GameNightModel]{
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/userFeed/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        //try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.getSession().data(for: request)
        
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let gameNights = try JSONDecoder().decode([GameNightModel].self, from: data)
        return gameNights
    }
    
    func getUserBoardGames(userID: Int) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/users/boardGames/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        //try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.getSession().data(for: request)
        
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let userBoardGames = try JSONDecoder().decode([BoardGameModel].self, from: data)
        return userBoardGames
    }
    
    func getGameNight(id: Int) async throws -> GameNightModel {
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/\(id)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        let (data, response) = try await client.getSession().data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        return try JSONDecoder().decode(GameNightModel.self, from: data)
    }

    func getUserGameNights(userID: Int) async throws -> [GameNightModel] {
        print("gettingUserGameNights")
        var components = URLComponents(string: baseURL)
        components?.path = "/gameNights/userGameNights/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        //try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.getSession().data(for: request)
        
        print("did i get here?")
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let userGameNights = try JSONDecoder().decode([GameNightModel].self, from: data)
        print(userGameNights)
        return userGameNights
    }
    
}
