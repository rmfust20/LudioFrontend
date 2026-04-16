//
//  UserSearchViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 4/12/26.
//

import Foundation
import Observation

@Observable
class UserSearchViewModel {
    var searchResults: [UserPublicModel] = []
    var profileImages: [Int: String] = [:]
    var isLoading: Bool = false

    private var userService: UserService
    private var imageService: ImageService
    private var searchTask: Task<Void, Never>?

    init(userService: UserService = UserService(), imageService: ImageService = ImageService()) {
        self.userService = userService
        self.imageService = imageService
    }

    func performSearch(searchText: String, accessToken: String) {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            searchResults = []
            profileImages = [:]
            isLoading = false
            return
        }

        searchTask = Task { @MainActor in
            do {
                self.isLoading = true
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else {
                    self.isLoading = false
                    return
                }
                let results = try await self.userService.searchUsers(username: searchText, accessToken: accessToken)
                guard !Task.isCancelled else {
                    self.isLoading = false
                    return
                }
                self.searchResults = results.sorted {
                    relevanceScore($0.username, query: searchText) < relevanceScore($1.username, query: searchText)
                }
                self.profileImages = await self.fetchProfileImages(for: results.map { $0.id }, accessToken: accessToken)
                self.isLoading = false
            } catch is CancellationError {
                self.isLoading = false
            } catch {
                self.searchResults = []
                self.profileImages = [:]
                self.isLoading = false
            }
        }
    }

    private func relevanceScore(_ name: String, query: String) -> Int {
        let name = name.lowercased()
        let query = query.lowercased()
        if name == query { return 0 }
        if name.hasPrefix(query) { return 1 }
        if name.split(separator: " ").contains(where: { $0.hasPrefix(query) }) { return 2 }
        if name.contains(query) { return 3 }
        return 4
    }

    private func fetchProfileImages(for userIDs: [Int], accessToken: String) async -> [Int: String] {
        let profiles = (try? await userService.getUsers(userIDs: userIDs, accessToken: accessToken)) ?? []
        let blobEntries: [(Int, String)] = profiles.compactMap { p in
            guard let blob = p.profile_image_url else { return nil }
            return (p.id, blob)
        }
        guard !blobEntries.isEmpty else { return [:] }
        let urlMap = (try? await imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)) ?? [:]
        var result: [Int: String] = [:]
        for (userID, blob) in blobEntries {
            if let url = urlMap[blob] {
                result[userID] = url
            }
        }
        return result
    }
}
