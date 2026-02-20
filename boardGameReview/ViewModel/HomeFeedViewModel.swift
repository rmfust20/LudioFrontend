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
    private let boardGameService: BoardGameService
    @Published var LastSeenID: Int = 0
    
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
            return
        }
        
        for key in feedKeys {
            if let cachedBoardGame = BoardGameCache.shared.get(id: key) {
                boardGamesInCache.append(cachedBoardGame)
            }
            
            self.boardGames.append(contentsOf: boardGamesInCache)
        }
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
            
            let combined = (trendingGames + trendingGamesFriends).sorted { $0.id < $1.id }
            
            self.boardGames = combined
            self.boardGames = self.boardGames.uniqued()
            LastSeenID += 25
            
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
    }

    
