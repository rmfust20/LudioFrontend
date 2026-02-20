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
        self.baseURL = "http://127.0.0.1:8000"
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
        
        let (responseData, response) = try await client.getSession().data(for: request)
        
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
        
        let (responseData, response) = try await client.getSession().data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
        return try JSONDecoder().decode(AuthResponse.self, from: responseData)
    }
    
}
