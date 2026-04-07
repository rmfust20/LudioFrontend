//
//  HomeFeedViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/21/26.
//

import Foundation
import UIKit


extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

class HomeFeedViewModel : ObservableObject {
    @Published var boardGames: [BoardGameModel] = []
    @Published var friendGames: [BoardGameModel] = []
    @Published private(set) var isFetchingMore = false
    private let boardGameService: BoardGameService
    private var offset = 0
    private var hasMore = true

    init(boardGameService: BoardGameService = BoardGameService()) {
        self.boardGameService = boardGameService
    }
    
    @MainActor
    func fetchBoardGames(userID : Int, accessToken: String) async {
        var boardGamesInCache: [BoardGameModel] = []
        //here we first check our cache for existing board games before fetching more from the network
        let feedKeys = BoardGameCache.shared.getFeedKeys()
        
        // if no feed keys just go to network and we are done
        if feedKeys.count == 0 {
            boardGames = await fetchBoardGamesFromNetwork(userID: userID, accessToken: accessToken)
            print(boardGames)
            return
        }
        
        for key in feedKeys {
            if let cachedBoardGame = BoardGameCache.shared.get(id: key) {
                boardGamesInCache.append(cachedBoardGame)
            }
            
            self.boardGames.append(contentsOf: boardGamesInCache)
        }
        print(boardGames)
    }
        
        @MainActor
        func fetchBoardGamesFromNetwork(userID: Int, accessToken: String) async -> [BoardGameModel] {
            var trendingGames = [BoardGameModel]()
            var trendingGamesFriends = [BoardGameModel]()
            let trendingFeed = try? await boardGameService.fetchGeneralTrendingFeed(accessToken: accessToken)
            let trendingWithFriends = try? await boardGameService.fetchTrendingWithFriends(userID: userID, accessToken: accessToken)
            if let trendingFeed = trendingFeed{
                for boardGame in trendingFeed {
                    trendingGames.append(boardGame)
                }
            }
            
            if let trendingWithFriends = trendingWithFriends {
                for boardGame in trendingWithFriends {
                    trendingGamesFriends.append(boardGame)
                }
            }

            self.friendGames = trendingGamesFriends.uniqued()

            let combined = (trendingGames + trendingGamesFriends).sorted { $0.id < $1.id }
            let newGames = combined.uniqued().filter { !self.friendGames.contains($0) }
            let existingIDs = Set(self.boardGames.map { $0.id })
            let trulyNew = newGames.filter { !existingIDs.contains($0.id) }
            self.boardGames.append(contentsOf: trulyNew)

            return boardGames
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
    
    @MainActor
    func tempGetBoardGameFeed(accessToken: String) async {
        offset = 0
        hasMore = true
        let feed = try? await boardGameService.fetchGeneralTrendingFeed(accessToken: accessToken, offset: 0)
        if let feed {
            self.boardGames = feed
            self.offset = feed.count
        }
    }

    func loadMore(accessToken: String) async {
        guard !isFetchingMore, hasMore else { return }
        await MainActor.run { isFetchingMore = true }

        let newGames = try? await boardGameService.fetchGeneralTrendingFeed(accessToken: accessToken, offset: offset)

        guard let newGames, !newGames.isEmpty else {
            await MainActor.run { hasMore = false; isFetchingMore = false }
            return
        }

        let existingIDs = Set(boardGames.map { $0.id })
        let dedupedGames = newGames.filter { !existingIDs.contains($0.id) }
        guard !dedupedGames.isEmpty else {
            await MainActor.run { hasMore = false; isFetchingMore = false }
            return
        }

        await MainActor.run {
            boardGames.append(contentsOf: dedupedGames)
            offset += newGames.count
            isFetchingMore = false
        }
    }
    }

    
