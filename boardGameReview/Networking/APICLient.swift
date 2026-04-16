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

    private static let maxRetries = 2
    private static let retryBaseDelay: UInt64 = 300_000_000 // 0.3s in nanoseconds

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 20
        config.waitsForConnectivity = false
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
    /// then retries. Also retries transient network failures with exponential backoff.
    /// Only triggers token refresh if the request had an Authorization header.
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        let (data, response) = try await sendWithRetry(request)

        guard let http = response as? HTTPURLResponse,
              http.statusCode == 401,
              request.value(forHTTPHeaderField: "Authorization") != nil else {
            return (data, response)
        }

        let newToken = try await refreshAccessToken()

        var retried = request
        retried.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
        return try await sendWithRetry(retried)
    }

    /// Sends a request, retrying on transient network errors. Only retries for
    /// errors that almost certainly mean the request never reached the server,
    /// so POST/PATCH/DELETE can't be accidentally duplicated.
    private func sendWithRetry(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var attempt = 0
        while true {
            do {
                return try await session.data(for: request)
            } catch let error as URLError where Self.isRetryable(error) && attempt < Self.maxRetries {
                attempt += 1
                try await Task.sleep(nanoseconds: Self.retryBaseDelay << (attempt - 1))
                continue
            }
        }
    }

    private static func isRetryable(_ error: URLError) -> Bool {
        switch error.code {
        case .timedOut,
             .cannotConnectToHost,
             .cannotFindHost,
             .dnsLookupFailed,
             .notConnectedToInternet,
             .networkConnectionLost:
            return true
        default:
            return false
        }
    }

    private func refreshAccessToken() async throws -> String {
        let task = await refreshState.existingOrNew {
            Task<String, Error> {
                let result: String
                do {
                    result = try await self.performRefresh()
                } catch {
                    await self.refreshState.clear()
                    throw error
                }
                await self.refreshState.clear()
                return result
            }
        }

        return try await task.value
    }

    private func performRefresh() async throws -> String {
        guard let auth = self.auth else { throw APIError.missingAccessToken }
        guard let refreshToken = await auth.refreshToken else {
            await auth.clear()
            throw APIError.missingAccessToken
        }

        var components = URLComponents(string: self.baseURL)
        components?.path = "/users/refresh"
        guard let url = components?.url else { throw APIError.invalidURL }

        var refreshRequest = URLRequest(url: url)
        refreshRequest.httpMethod = "POST"
        refreshRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        refreshRequest.httpBody = try JSONEncoder().encode(["refresh_token": refreshToken])

        let (data, response) = try await self.session.data(for: refreshRequest)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }

        guard (200...299).contains(http.statusCode) else {
            await auth.clear()
            throw APIError.httpStatus(http.statusCode)
        }

        let refreshed = try JSONDecoder().decode(RefreshTokenResponse.self, from: data)
        let username = await auth.username ?? ""
        let userID = await auth.userID ?? 0
        await auth.setSession(AuthResponse(
            access_token: refreshed.access_token,
            refresh_token: refreshed.refresh_token,
            token_type: refreshed.token_type,
            user: RegisterResponse(username: username, id: userID)
        ))

        return refreshed.access_token
    }
}


