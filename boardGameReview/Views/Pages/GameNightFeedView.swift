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
    @EnvironmentObject private var feedRefresh: FeedRefreshCoordinator
    @StateObject private var gameNightFeedViewModel = GameNightFeedViewModel()
    let userOnly: Int?
    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    HStack {
                        Text("Game Nights")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                        if gameNightFeedViewModel.gameNightPresent.isEmpty && gameNightFeedViewModel.isLoading == false{
                            VStack(spacing: 12) {
                                Image(systemName: "person.2.slash")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.gray)
                                Text("Add friends to see their game nights")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        }
                        ForEach(gameNightFeedViewModel.gameNightPresent) { gameNight in
                            GameNightCardView(gameNight: gameNight, onDelete: {
                                gameNightFeedViewModel.removeGameNight(id: gameNight.id)
                            })
                        }
                        

                        if gameNightFeedViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                                .padding(.vertical, 16)
                        }

                        Color.clear
                            .frame(height: 1)
                            .onAppear {
                                if gameNightFeedViewModel.isLoading == false && gameNightFeedViewModel.gameNightPresent.count >= 10 {
                                    Task {
                                        await gameNightFeedViewModel.fetchMoreGameNights(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "", userOnly: userOnly)
                                    }
                                }
                            }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    router.push(.addGameNight(id: 1))
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(.white)
                }
            }
        }
        .toolbarBackground(Color("CharcoalBackground"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            Task {
                await gameNightFeedViewModel.fetchMoreGameNights(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "", userOnly: userOnly)
            }
        }
        .onChange(of: router.gameNightPosted) {
            if router.gameNightPosted {
                router.gameNightPosted = false
                Task {
                    await gameNightFeedViewModel.reset()
                }
            }
        }
        .onChange(of: feedRefresh.friendsChanged) {
            if feedRefresh.friendsChanged {
                feedRefresh.friendsChanged = false
                Task {
                    await gameNightFeedViewModel.reset()
                    await gameNightFeedViewModel.fetchMoreGameNights(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "", userOnly: userOnly)
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
    return GameNightFeedView(userOnly: nil)
        .environmentObject(auth)
        .environmentObject(AppRouter())
}
