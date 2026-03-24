//
//  GameNightFeedView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/5/26.
//

import SwiftUI

struct GameNightFeedView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: Auth
    @StateObject private var gameNightFeedViewModel = GameNightFeedViewModel()
    let userOnly: Bool
    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Game Nights")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    LazyVStack(spacing: 16) {
                        ForEach(gameNightFeedViewModel.gameNights) { gameNight in
                            GameNightCardView(
                                gameNight: gameNight,
                                boardGames: gameNightFeedViewModel.boardGames
                                    .filter { gameNight.sessions.map { $0.board_game_id }.contains($0.key) }
                                    .map { ($0.key, $0.value) }
                            )
                        }

                        Button {
                            router.push(.addGameNight(id: 1))
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 16))
                                Text("Post a Game Night")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("PrimaryButton"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            Task {
                                if userOnly == true {
                                    await gameNightFeedViewModel.fetchUserGameNights(userID: auth.userID ?? 1)
                                } else {
                                    await gameNightFeedViewModel.fetchGameNights(userID: auth.userID ?? 1)
                                }
                                async let boardGames: () = gameNightFeedViewModel.fetchBoardGameDetails()
                                async let imageURLs: () = {
                                    await withTaskGroup(of: Void.self) { group in
                                        for gameNight in await gameNightFeedViewModel.gameNights {
                                            let id = gameNight.id
                                            let blobNames = gameNight.images ?? []
                                            group.addTask {
                                                await gameNightFeedViewModel.fetchImageURLFromBlob(id: id, blobNames: blobNames)
                                            }
                                        }
                                    }
                                }()
                                await boardGames
                                await imageURLs
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

#Preview {
    let auth = Auth()
    auth.setSession(AuthResponse(
        access_token: "preview-token",
        refresh_token: "preview-refresh",
        token_type: "bearer",
        user: RegisterResponse(username: "previewUser", id: 2)
    ))
    return GameNightFeedView(userOnly: false)
        .environmentObject(auth)
        .environmentObject(AppRouter())
}
