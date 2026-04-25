//
//  HomeView.swift
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: Auth
    @StateObject var homeFeedViewModel = HomeFeedViewModel()
    @ObservedObject var reviewViewModel = ReviewViewModel()
    @State private var isSearchPresented: Bool = false
    @State private var selectedBoardGameID: Int? = nil
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    // Header
                    HStack(alignment: .center) {
                        Text("Trending Games")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(Color.white)
                        Spacer()
                        Button {
                            isSearchPresented = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Color.white)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                        ForEach(homeFeedViewModel.boardGames) { boardGame in
                            Button {
                                router.push(.boardGame(id: boardGame.id))
                            } label: {
                                FeedCard(boardGame: boardGame)
                            }
                            .padding(.horizontal, 12)
                        }
                    if homeFeedViewModel.isLoading {
                        ProgressView()
                            .tint(.white)
                            .padding(.vertical, 16)
                    }

                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            if homeFeedViewModel.isLoading == false && homeFeedViewModel.boardGames.count >= 10 {
                                Task {
                                    await homeFeedViewModel.fetchMoreBoardGames(accessToken: auth.accessToken ?? "")
                                }
                            }
                        }
                    }
                .onAppear {
                    Task {
                        await homeFeedViewModel.fetchMoreBoardGames(accessToken: auth.accessToken ?? "")
                    }
                }
                }
            }
            .fullScreenCover(isPresented: $isSearchPresented) {
                SearchView(isPresented: $isSearchPresented, selectedBoardGameID: $selectedBoardGameID)
                    .onChange(of: selectedBoardGameID) {
                        if let id = selectedBoardGameID {
                            isSearchPresented = false
                            router.push(.boardGame(id: id))
                            selectedBoardGameID = nil
                        }
                    }
            }
        }
    }

// MARK: - Feed Card

private struct FeedCard: View {
    let boardGame: BoardGameModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image with gradient + title overlay
            ZStack(alignment: .bottomLeading) {
                AsyncImage(url: URL(string: boardGame.image ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.12))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundStyle(Color.gray.opacity(0.3))
                            )
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 154)
                .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 154)

                Text(boardGame.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)
            }

            // Metadata + rate row
            HStack(spacing: 8) {
                if let min = boardGame.min_players, let max = boardGame.max_players {
                    MetaBadge(icon: "person.2.fill", label: "\(min)–\(max)")
                }
                if let time = boardGame.play_time, time > 0 {
                    MetaBadge(icon: "clock.fill", label: "\(time) min")
                }
                if let year = boardGame.year_published {
                    MetaBadge(icon: "calendar", label: "\(year)")
                }

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                    Text("Rate")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(Color("PrimaryButton"))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color("PrimaryButton").opacity(0.12))
                .clipShape(Capsule())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(Color("CardSurface").opacity(0.5))
        }
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Friends Trending Card

private struct FriendsTrendingCard: View {
    let boardGame: BoardGameModel
    let cardImage: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image = cardImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.12))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.gray.opacity(0.3))
                        )
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color("PrimaryButton"))
                    Text("TRENDING WITH FRIENDS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Color("PrimaryButton"))
                        .tracking(1)
                }
                Text(boardGame.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                if let time = boardGame.play_time, time > 0,
                   let min = boardGame.min_players, let max = boardGame.max_players {
                    Text("\(min)–\(max) players · \(time) min")
                        .font(.system(size: 12))
                        .foregroundStyle(Color("MutedText"))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color("MutedText"))
        }
        .padding(14)
        .background(Color("CardSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Meta Badge

private struct MetaBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color("MutedText"))
    }
}

// MARK: - Add Stars Sheet


#Preview {
    let auth = Auth()
    auth.setSession(AuthResponse(
        access_token: "preview-token",
        refresh_token: "preview-refresh",
        token_type: "bearer",
        user: RegisterResponse(username: "previewUser", id: 1)
    ))
    return HomeView()
        .environmentObject(auth)
        .environmentObject(AppRouter())
}
