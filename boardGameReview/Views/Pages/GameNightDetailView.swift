//
//  GameNightDetailView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/24/26.
//

import SwiftUI

struct GameNightDetailView: View {
    let gameNightID: Int
    @StateObject private var viewModel = GameNightDetailViewModel()

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Game Night")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    if let gameNight = viewModel.gameNight {
                        GameNightCardView(
                            gameNight: gameNight,
                            boardGames: viewModel.boardGames
                                .filter { gameNight.sessions.map { $0.board_game_id }.contains($0.key) }
                                .map { ($0.key, $0.value) }
                        )
                        .padding(.horizontal, 16)
                    } else {
                        ProgressView()
                            .tint(.white)
                            .padding(.top, 60)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchGameNight(id: gameNightID)
                await viewModel.fetchBoardGameDetails()
            }
        }
    }
}

#Preview {
    GameNightDetailView(gameNightID: 1)
        .environmentObject(AppRouter())
}
