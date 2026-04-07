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
    @State private var isLoading: Bool = true
    let userOnly: Int?
    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    HStack {
                        Text("Game Nights")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        Button {
                            router.push(.addGameNight(id: 1))
                        } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 32))
                            .foregroundStyle(.white)
                            .padding(.vertical, 16)

                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    VStack(spacing: 16) {
                        if gameNightFeedViewModel.gameNightPresent.isEmpty && !isLoading {
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
                            GameNightCardView(gameNight: gameNight)
                        }
                        if !isLoading {
                            Color.clear
                                .frame(height: 1)
                                .onAppear {
                                    Task {
                                        await gameNightFeedViewModel.loadMore(userID: auth.userID ?? 1, userOnly: userOnly, accessToken: auth.accessToken ?? "")
                                    }
                                }
                            if gameNightFeedViewModel.isFetchingMore {
                                ProgressView().tint(.white).padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .overlay {
            if isLoading {
                Color("CharcoalBackground").ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .task {
            guard gameNightFeedViewModel.gameNightPresent.isEmpty else { return }
            await loadFeed()
        }
        .onChange(of: router.gameNightPosted) {
            guard router.gameNightPosted else { return }
            router.gameNightPosted = false
            Task { await loadFeed() }
        }
    }

    private func loadFeed() async {
        isLoading = true
        gameNightFeedViewModel.gameNightPresent = []
        let token = auth.accessToken ?? ""
        if let userOnly {
            await gameNightFeedViewModel.fetchUserGameNights(userID: userOnly, accessToken: token)
        } else {
            await gameNightFeedViewModel.fetchGameNights(userID: auth.userID ?? 1, accessToken: token)
        }
        let nights = gameNightFeedViewModel.gameNights
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await gameNightFeedViewModel.fetchUserProfileImages(for: nights, accessToken: token) }
            group.addTask { await gameNightFeedViewModel.fetchAllGameNightImages(for: nights, accessToken: token) }
        }
        await gameNightFeedViewModel.prepareFinalModel()
        isLoading = false
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
