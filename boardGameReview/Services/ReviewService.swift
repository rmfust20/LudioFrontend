//
//  ReviewService.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/5/26.
//

import Foundation

struct ReviewService {
    let client: APIClient
    let baseURL: String

    init(client: APIClient = APIClient.shared) {
        self.client = client
        self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
    }
    
    func postReview(review: ReviewModel, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/postReview"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(review)
        request.httpBody = data
        
        let (responseData, response) = try await client.data(for: request)
        
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
    }
    
    func getReviews(boardGameID: Int, offset: Int = 0, accessToken: String) async throws -> [ReviewPublicModel] {
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/boardGame/\(boardGameID)"
        components?.queryItems = [URLQueryItem(name: "offset", value: "\(offset)")]
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        let reviews = try JSONDecoder().decode([ReviewPublicModel].self, from: data)
        print(reviews)
        return reviews

    }
    
    func getReviewStats(boardGameID: Int, accessToken: String) async throws -> ReviewStatsModel {
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/reviewStats/\(boardGameID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }

        let reviewStats = try JSONDecoder().decode(ReviewStatsModel.self, from: data)
        
        return reviewStats
    }
    
    func getUserReview(boardGameID: Int, userID: Int, accessToken: String) async throws -> ReviewModel? {
        print("triggr")
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/userBoardGame/\(userID)/\(boardGameID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        print("")
        let review = try JSONDecoder().decode(ReviewModel.self, from: data)
        print(review.rating)
        return review
    }
    
    func getPinnedReview(boardGameID: Int, userID: Int, accessToken: String) async throws -> ReviewPublicModel? {
        print("triggr")
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews//\(userID)/\(boardGameID)"
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        let (data, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        print("")
        let review = try JSONDecoder().decode(ReviewPublicModel.self, from: data)
        print(review.rating)
        return review
    }
    
    
    
    func deleteReview(reviewID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/\(reviewID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        request.httpMethod = "DELETE"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }

    func updateReview(reviewID: Int, update: ReviewUpdate, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/editReview/\(reviewID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(update)

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
    }
    
    func reportReview(reviewID: Int, accessToken: String) async throws {
        var components = URLComponents(string: baseURL)
        components?.path = "/reviews/reportReview/\(reviewID)"
        guard let url = components?.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        try client.authorizedRequest(&request, accessToken: accessToken)

        request.httpMethod = "POST"

        let (_, response) = try await client.data(for: request)

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200...299).contains(http.statusCode) else { throw APIError.httpStatus(http.statusCode) }
        
    }
 }
