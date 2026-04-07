//
//  APIClient.swift
//  BoardGameReview
//
//  Created by Robert Fusting on 12/6/25.
//

import Foundation

private actor RefreshState {
    private var task: Task<String, Error>?

    func existingOrNew(_ make: () -> Task<String, Error>) -> Task<String, Error> {
        if let t = task { return t }
        let t = make()
        task = t
        return t
    }

    func clear() { task = nil }
}

final class APIClient {

    static let shared = APIClient()
    private let session: URLSession
    private let baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"

    var auth: Auth?
    private let refreshState = RefreshState()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        self.session = URLSession(configuration: config)
    }

    func authorizedRequest(_ request: inout URLRequest, accessToken: String?) throws {
        guard let token = accessToken, !token.isEmpty else {
            throw APIError.missingAccessToken
        }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    func getSession() -> URLSession {
        return session
    }

    /// Performs a request and automatically refreshes the access token on 401,
    /// then retries. Only triggers refresh if the request had an Authorization header.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await session.data(for: request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 401,
              request.value(forHTTPHeaderField: "Authorization") != nil else {
            return (data, response)
        }

        let newToken = try await refreshAccessToken()

        var retried = request
        retried.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        return try await session.data(for: retried)
    }

    private func refreshAccessToken() async throws -> String {
        let task = await refreshState.existingOrNew {
            Task<String, Error> {
                defer { Task { await self.refreshState.clear() } }

                guard let auth = self.auth else { throw APIError.missingAccessToken }
                guard let refreshToken = auth.refreshToken else {
                    await MainActor.run { auth.clear() }
                    throw APIError.missingAccessToken
                }

                var components = URLComponents(string: self.baseURL)
                components?.path = "/users/refresh"
                components?.queryItems = [URLQueryItem(name: "refresh_token", value: refreshToken)]
                guard let url = components?.url else { throw APIError.invalidURL }

                var refreshRequest = URLRequest(url: url)
                refreshRequest.httpMethod = "POST"

                let (data, response) = try await self.session.data(for: refreshRequest)
                guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

                guard (200...299).contains(http.statusCode) else {
                    await MainActor.run { auth.clear() }
                    throw APIError.httpStatus(http.statusCode)
                }

                let refreshed = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
                let username = auth.username ?? ""
                let userID = auth.userID ?? 0
                await MainActor.run {
                    auth.setSession(AuthResponse(
                        access_token: refreshed.access_token,
                        refresh_token: refreshed.refresh_token,
                        token_type: refreshed.token_type,
                        user: RegisterResponse(username: username, id: userID)
                    ))
                }

                return refreshed.access_token
            }
        }

        return try await task.value
    }
}


