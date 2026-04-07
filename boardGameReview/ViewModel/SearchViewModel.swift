//
//  SearchViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/24/26.
//

import Foundation
import Observation
import UIKit

@Observable
class SearchViewModel {
    var searchResults: [BoardGameModel] = []
    var images: [Int: UIImage] = [:]
    var isLoading: Bool = false

    private var boardGameService: BoardGameService
    private var searchTask: Task<Void, Never>?

    init(boardGameService: BoardGameService = BoardGameService()) {
        self.boardGameService = boardGameService
    }

    func performSearch(searchText: String, accessToken: String) {
        searchTask?.cancel()

        guard !searchText.isEmpty else {
            searchResults = []
            isLoading = false
            return
        }

        searchTask = Task { @MainActor in
            do {
                self.isLoading = true
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
                guard !Task.isCancelled else {
                    self.isLoading = false
                    return
                }
                let result = try await self.boardGameService.fetchBoardGames(name: searchText, accessToken: accessToken)
                guard !Task.isCancelled else {
                    self.isLoading = false
                    return
                }
                self.searchResults = result.sorted { relevanceScore($0.name, query: searchText) < relevanceScore($1.name, query: searchText) }
                self.isLoading = false
            } catch is CancellationError {
                self.isLoading = false
            } catch {
                print("Error fetching search results: \(error)")
                self.searchResults = []
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

    func loadImage(for boardGame: BoardGameModel) {
        guard images[boardGame.id] == nil else { return }
        if let cached = ImageCache.shared.getImage(for: boardGame.id) {
            images[boardGame.id] = cached
            return
        }
        Task { @MainActor in
            let networkImage = try? await self.boardGameService.fetchBoardGameImage(boardGame.image ?? "")
            if let networkImage {
                self.images[boardGame.id] = networkImage
                ImageCache.shared.storeImage(networkImage, for: boardGame.id)
            }
        }
    }
}
