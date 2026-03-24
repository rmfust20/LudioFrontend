//
//  GameNightDetailViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/24/26.
//

import Foundation

class GameNightDetailViewModel: ObservableObject {
    private let gameNightService: GameNightService
    private let boardGameService: BoardGameService

    @Published var gameNight: GameNightModel?
    @Published var boardGames: [Int: String] = [:]

    init(gameNightService: GameNightService = GameNightService(), boardGameService: BoardGameService = BoardGameService()) {
        self.gameNightService = gameNightService
        self.boardGameService = boardGameService
    }

    @MainActor
    func fetchGameNight(id: Int) async {
        let night = try? await gameNightService.getGameNight(id: id)
        if let night = night {
            self.gameNight = night
        }
    }

    @MainActor
    func fetchBoardGameDetails() async {
        guard let gameNight = gameNight else { return }

        let boardGameIDs = gameNight.sessions.map { $0.board_game_id }
        let games = try? await boardGameService.fetchBoardGamesByIds(ids: boardGameIDs)

        if let games = games {
            for game in games {
                self.boardGames[game.id] = game.image ?? game.name
            }
        }
    }
}
