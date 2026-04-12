import Foundation
import UIKit

struct BoardGameService {
    let client: APIClient
    let baseURL: String

    init(client: APIClient = APIClient.shared) {
        self.client = client
        //self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
        self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
    }
    
    func fetchGeneralTrendingFeed(accessToken: String, offset: Int = 0) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/boardGames/trendingFeed"
        components?.queryItems = [URLQueryItem(name: "offset", value: "\(offset)")]
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        let boardGames = try JSONDecoder().decode([BoardGameModel].self, from: data)
        return boardGames
    }
    
    func fetchHotBoardGames(accessToken: String, offset: Int = 0, limit: Int = 25) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/boardGames/hot"
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

        return try JSONDecoder().decode([BoardGameModel].self, from: data)
    }

    func fetchBoardGamesByIds(ids: [Int], accessToken: String) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/boardGames/boardGamesByIds"
        components?.queryItems = ids.map { URLQueryItem(name: "board_game_ids", value: String($0)) }
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)
        
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let boardGames = try JSONDecoder().decode([BoardGameModel].self, from: data)
        return boardGames
    }
        
        
    
    func fetchTrendingWithFriends(userID: Int, accessToken: String) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/boardGames/trendingFriends/\(userID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let boardGames = try JSONDecoder().decode([BoardGameModel].self, from: data)
        
        return boardGames
    }
    
    func fetchBoardGame(boardGameID: Int, accessToken: String) async throws -> BoardGameModel {
        var components = URLComponents(string: baseURL)
        components?.path = "/boardGames/fetchBoardGame/\(boardGameID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let boardGame = try JSONDecoder().decode(BoardGameModel.self, from: data)
        
        return boardGame

    }
    
    func fetchBoardGames(name: String, accessToken: String) async throws -> [BoardGameModel] {
        var components = URLComponents(string: baseURL)
        var pathAllowed = CharacterSet.urlPathAllowed
        pathAllowed.remove("/")
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: pathAllowed) ?? name
        components?.path = "/boardGames/search/\(encodedName)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        // ✅ Use the request, not the raw url
        let (data, response) = try await client.data(for: request)
        
        

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        let boardGames = try JSONDecoder().decode([BoardGameModel].self, from: data)
        
        return boardGames
    }

    func fetchBoardGameFeedForUser(_ userID: String, _ url: inout String, _ lastSeenID: Int, accessToken:String) async throws -> [BoardGameModel] {
        if lastSeenID > 0 {
            url += "?lastSeenID=\(lastSeenID)"
        }
        
        guard let url = URL(string: url) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)


        let (data, response) = try await client.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0,
                                       message: "Server error")
        }

        return try JSONDecoder().decode([BoardGameModel].self, from: data)
    }
    
    func rehydrate(userID: Int, boardGameIds: [Int], accessToken: String) async throws -> [BoardGameModel] {
            guard !boardGameIds.isEmpty else { return [] }

            var components = URLComponents(string: baseURL)
            components?.path = "/boardGames/userFeed/\(userID)/rehydrate"
            components?.queryItems = boardGameIds.map { URLQueryItem(name: "board_game_ids", value: String($0)) }
        

            guard let url = components?.url else { throw APIError.invalidURL }
            var request = URLRequest(url: url)
            try client.authorizedRequest(&request, accessToken: accessToken)

            let (data, response) = try await client.data(for: request)

            guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
            guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

            return try JSONDecoder().decode([BoardGameModel].self, from: data)
        }
    
    
    func fetchBoardGameImage(_ urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        let (data, response) = try await client.getSession().data(from: url)

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpStatus(http.statusCode)
        }

        guard let image = UIImage(data: data) else {
            throw APIError.invalidImageData
        }

        return image
    }
    
    func fetchBoardGameDesigners(_ boardGameID: Int, accessToken: String) async throws -> [String] {
        var components = URLComponents(string: baseURL)
        components?.path = "/boardGames/designers/\(boardGameID)"

        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        let designers = try JSONDecoder().decode([BoardGameDesingnerModel].self, from: data)
        return designers.map { $0.name }.sorted()
    }
}

