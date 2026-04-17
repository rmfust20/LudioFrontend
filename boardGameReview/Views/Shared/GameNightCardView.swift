//
//  GameNightCardView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/8/26.
//

import SwiftUI

struct GameNightCardView: View {
    let gameNight: GameNightFeedModel
    var onDelete: (() -> Void)? = nil
    @EnvironmentObject private var auth: Auth
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var feedRefresh: FeedRefreshCoordinator
    @State private var showOptions: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var showDeleteError: Bool = false
    @State private var showReportConfirm: Bool = false
    @State private var showBlockConfirm: Bool = false
    @State private var isDescriptionExpanded = false
    @State private var isDescriptionTruncated = false
    @State private var fullDescriptionHeight: CGFloat? = nil
    @State private var clampedDescriptionHeight: CGFloat? = nil
    private let descriptionCollapsedLineLimit = 3
    private let gameNightService = GameNightService()
    private let userService = UserService()

    private var nonHostPlayers: [PlayerFeedModel] {
        gameNight.players.filter { $0.id != gameNight.hostUserID }
    }

    private var hostIsWinner: Bool {
        gameNight.players.first { $0.id == gameNight.hostUserID }?.isWinner ?? false
    }

    private var boardGames: [(id: Int, imageURL: String)] {
        var seen = Set<Int>()
        return gameNight.sessions.compactMap { session in
            guard seen.insert(session.board_game.id).inserted,
                  let image = session.board_game.image else { return nil }
            return (session.board_game.id, image)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Header
            HStack(spacing: 12) {
                ZStack(alignment: .bottom) {
                    Button {
                        router.push(.profile(id: gameNight.hostUserID, username: gameNight.hostUsername))
                    } label: {
                        Group {
                            if let url = gameNight.hostProfileImageURL {
                                RetryAsyncImage(url: URL(string: url)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    ProgressView()
                                }
                            } else {
                                Image(systemName: "person.circle.fill")
                                    .resizable()
                                    .foregroundStyle(Color("MutedText"))
                            }
                        }
                        .frame(width: 42, height: 42)
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(hostIsWinner ? Color.yellow : Color.clear, lineWidth: 2.5)
                        )
                    }

                    if hostIsWinner {
                        Text("Winner")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.yellow)
                            .clipShape(Capsule())
                            .offset(y: 8)
                    }
                }
                .padding(.bottom, hostIsWinner ? 8 : 0)
                VStack(alignment: .leading, spacing: 2) {
                    Button {
                        router.push(.profile(id: gameNight.hostUserID, username: gameNight.hostUsername))
                    } label: {
                        Text(gameNight.hostUsername)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }.buttonStyle(.plain)
                    Text(formattedDate(gameNight.date))
                        .font(.system(size: 12))
                        .foregroundStyle(Color("MutedText"))
                }
                Spacer()
                Button {
                    showOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color("MutedText"))
                        .padding(.trailing, 4)
                }
                .buttonStyle(.plain)
                .confirmationDialog("", isPresented: $showOptions) {
                    if gameNight.hostUserID == auth.userID {
                        Button("Delete Post", role: .destructive) {
                            showDeleteConfirm = true
                        }
                    } else {
                        Button("Report", role: .destructive) {
                            showReportConfirm = true
                        }
                        Button("Block", role: .destructive) {
                            showBlockConfirm = true
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                }
                .alert("Report this post?", isPresented: $showReportConfirm) {
                    Button("Report", role: .destructive) {
                        Task {
                            try? await gameNightService.reportGameNight(gameNightID: gameNight.id, accessToken: auth.accessToken ?? "")
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This post will be reported for review.")
                }
                .alert("Block \(gameNight.hostUsername)?", isPresented: $showBlockConfirm) {
                    Button("Block", role: .destructive) {
                        Task {
                            try? await userService.blockUser(userID: gameNight.hostUserID, accessToken: auth.accessToken ?? "")
                            feedRefresh.friendsChanged += 1
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("You won't see their reviews or game nights anymore.")
                }
                .alert("Delete Post?", isPresented: $showDeleteConfirm) {
                    Button("Delete", role: .destructive) {
                        Task {
                            do {
                                try await gameNightService.deleteGameNight(gameNightID: gameNight.id, accessToken: auth.accessToken ?? "")
                                onDelete?()
                            } catch {
                                showDeleteError = true
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently delete this game night post.")
                }
                .alert("Delete Failed", isPresented: $showDeleteError) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("Failed to delete this post. Please try again.")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            // Game night photos
            if !gameNight.photos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(gameNight.photos, id: \.self) { urlString in
                            RetryAsyncImage(url: URL(string: urlString)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.12))
                                    .overlay(ProgressView())
                            }
                            .frame(width: 300, height: 300)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                    }
                    .padding(.horizontal, 14)
                }
            }

            // Players
            // Board games played
            if !boardGames.isEmpty {
                
                Text("Played")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color("MutedText"))
                    .tracking(1.5)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(boardGames, id: \.id) { item in
                            Button {
                                router.push(.boardGame(id: item.id))
                            } label: {
                                RetryAsyncImage(url: URL(string: item.imageURL)) { image in
                                    image.resizable().scaledToFill()
                                } placeholder: {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.12))
                                        .overlay(ProgressView())
                                }
                                .frame(width: gameNight.photos.isEmpty ? 170 : 130, height: gameNight.photos.isEmpty ? 170 : 130)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                }
            }
        
            
            if !nonHostPlayers.isEmpty {
                Text("Players")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color("MutedText"))
                    .tracking(1.5)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(nonHostPlayers) { player in
                            Button {
                                router.push(.profile(id: player.id, username: player.username))
                            } label: {
                                ZStack(alignment: .bottom) {
                                    Group {
                                        if let url = player.profileImageURL {
                                            RetryAsyncImage(url: URL(string: url)) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                ProgressView()
                                            }
                                        } else {
                                            Image(systemName: "person.circle.fill")
                                                .resizable()
                                                .foregroundStyle(Color("MutedText"))
                                        }
                                    }
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(player.isWinner ? Color.yellow : Color.clear, lineWidth: 2.5)
                                    )

                                    if player.isWinner {
                                        Text("Winner")
                                            .font(.system(size: 7, weight: .bold))
                                            .foregroundStyle(.black)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 2)
                                            .background(Color.yellow)
                                            .clipShape(Capsule())
                                            .offset(y: 8)
                                    }
                                }
                                .padding(.bottom, player.isWinner ? 8 : 0)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                }
            }

            // Description
            if let description = gameNight.description, !description.isEmpty {
                Rectangle()
                    .fill(Color("MutedText").opacity(0.30))
                    .frame(height: 1)
                    .padding(.vertical, 12)
                VStack(alignment: .leading, spacing: 6) {
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .lineLimit(isDescriptionExpanded ? nil : descriptionCollapsedLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            Text(description)
                                .font(.system(size: 14))
                                .fixedSize(horizontal: false, vertical: true)
                                .hidden()
                                .background(GeometryReader { full in
                                    Color.clear.preference(
                                        key: GameNightDescFullHeightKey.self,
                                        value: full.size.height
                                    )
                                })
                        )
                        .background(
                            Text(description)
                                .font(.system(size: 14))
                                .lineLimit(descriptionCollapsedLineLimit)
                                .fixedSize(horizontal: false, vertical: true)
                                .hidden()
                                .background(GeometryReader { clamped in
                                    Color.clear.preference(
                                        key: GameNightDescClampedHeightKey.self,
                                        value: clamped.size.height
                                    )
                                })
                        )
                        .onPreferenceChange(GameNightDescFullHeightKey.self) { fullHeight in
                            evaluateDescriptionTruncation(fullHeight: fullHeight, clampedHeight: nil)
                        }
                        .onPreferenceChange(GameNightDescClampedHeightKey.self) { clampedHeight in
                            evaluateDescriptionTruncation(fullHeight: nil, clampedHeight: clampedHeight)
                        }

                    if isDescriptionTruncated {
                        Button {
                            isDescriptionExpanded.toggle()
                        } label: {
                            Text(isDescriptionExpanded ? "See less" : "See more")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color("MutedText"))
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
            }
        }
        .padding(.bottom,14)
        .background(Color("CardSurface").opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    private func evaluateDescriptionTruncation(fullHeight: CGFloat?, clampedHeight: CGFloat?) {
        if let full = fullHeight {
            fullDescriptionHeight = full
        }
        if let clamped = clampedHeight {
            clampedDescriptionHeight = clamped
        }
        guard let full = fullDescriptionHeight, let clamped = clampedDescriptionHeight else { return }
        let shouldTruncate = full > clamped + 0.5
        if shouldTruncate != isDescriptionTruncated {
            isDescriptionTruncated = shouldTruncate
        }
    }

    private func formattedDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none)
        }
        return dateString
    }
}

private struct GameNightDescFullHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct GameNightDescClampedHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

#Preview {
    GameNightCardView(
        gameNight: GameNightFeedModel(
            id: 0,
            hostUserID: 0,
            hostUsername: "previewUser",
            hostProfileImageURL: nil as String?,
            date: "2024-05-09T19:00:00Z",
            description: "I wanna be yours - arctic monkeys",
            photos: [],
            players: [
                PlayerFeedModel(id: 1, username: "alice", profileImageURL: nil, isWinner: true),
                PlayerFeedModel(id: 2, username: "bob", profileImageURL: nil, isWinner: false)
            ],
            sessions: [
                GameNightSessionModel(
                    board_game: BoardGameModel(
                        id: 181,
                        name: "Catan",
                        thumbnail: nil,
                        play_time: 90,
                        min_players: 3,
                        max_players: 4,
                        year_published: 1995,
                        description: nil,
                        min_age: 10,
                        image: "https://cf.geekdo-images.com/Oem1TTtSgxOghRFCoyWRPw__original/img/Nu3eXPyOkhtnR3hhpUrtgqRMAfs=/0x0/filters:format(jpeg)/pic4916782.jpg"
                    ),
                    duration_minutes: 90,
                    winners_user_id: [1]
                )
            ]
        )
    )
    .environmentObject(Auth())
    .environmentObject(AppRouter())
    .padding()
    .background(Color("CharcoalBackground"))
}
