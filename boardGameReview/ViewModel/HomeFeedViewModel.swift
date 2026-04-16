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
    @Published var isLoading = false
    private let boardGameService: BoardGameService
    private var offset = 0
    private let limit = 25

    init(boardGameService: BoardGameService = BoardGameService()) {
        self.boardGameService = boardGameService
    }

    @MainActor
    func fetchMoreBoardGames(accessToken: String) async {
        guard !isLoading else { return }
        isLoading = true
        let games = try? await boardGameService.fetchHotBoardGames(accessToken: accessToken, offset: offset, limit: limit)

        if let games {
            let newGames = games.filter { n in !boardGames.contains(where: { $0.id == n.id }) }
            boardGames.append(contentsOf: newGames)
            offset += games.count
        }

        isLoading = false
    }
}


