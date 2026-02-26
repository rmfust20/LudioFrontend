//
//  SearchViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/24/26.
//

import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchResults: [BoardGameModel] = []
    private var boardGameService = BoardGameService()
    
    init(boardGameService: BoardGameService = BoardGameService()) {
        self.boardGameService = boardGameService
    }
    
    @MainActor
    func performSearch(searchText: String) async {
        do {
            let result = try await boardGameService.fetchBoardGames(name: searchText)
            searchResults = result
        } catch {
            print("Error fetching search results: \(error)")
        }
    }
    
    @MainActor
    func updateImageCache(boardGame: BoardGameModel) async{
        let cachedImage = ImageCache.shared.getImage(for: boardGame.id)
        if cachedImage == nil {
            let networkImage = try? await boardGameService.fetchBoardGameImage(boardGame.image ?? "")
            if let networkImage = networkImage {
                //ID is always valid here because we were able to fetch the image from the network
                ImageCache.shared.storeImage(networkImage, for: boardGame.id)
            }
        }
    }
    
}
