//
//  GameNightFeedViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/7/26.
//

import Foundation

class GameNightFeedViewModel: ObservableObject {
    private let gameNightService: GameNightService
    private let imageService: ImageService
    @Published var gameNightPresent: [GameNightFeedModel] = []
    @Published private(set) var isFetchingMore = false
    var gameNights: [GameNightModel] = []
    var gameNightImageURLs: [Int: [String]] = [:]
    var userProfileImages: [Int: String] = [:]
    var usernames: [Int: String] = [:]
    private var offset = 0
    private var hasMore = true

    init(gameNightService: GameNightService = GameNightService(), imageService: ImageService = ImageService()) {
        self.gameNightService = gameNightService
        self.imageService = imageService
    }

    func fetchGameNights(userID: Int, accessToken: String) async {
        gameNightImageURLs = [:]
        userProfileImages = [:]
        usernames = [:]
        offset = 0
        hasMore = true
        let nights = try? await gameNightService.getGameNightFeed(userID: userID, offset: 0, accessToken: accessToken)
        if let nights {
            gameNights = nights
            offset = nights.count
        }
    }

    func fetchUserGameNights(userID: Int, accessToken: String) async {
        gameNightImageURLs = [:]
        userProfileImages = [:]
        usernames = [:]
        offset = 0
        hasMore = true
        let nights = try? await gameNightService.getUserGameNights(userID: userID, offset: 0, accessToken: accessToken)
        if let nights {
            gameNights = nights
            offset = nights.count
        }
    }

    func loadMore(userID: Int, userOnly: Int?, accessToken: String) async {
        guard !isFetchingMore, hasMore else { return }
        await MainActor.run { isFetchingMore = true }

        let newNights: [GameNightModel]?
        if let userOnly {
            newNights = try? await gameNightService.getUserGameNights(userID: userOnly, offset: offset, accessToken: accessToken)
        } else {
            newNights = try? await gameNightService.getGameNightFeed(userID: userID, offset: offset, accessToken: accessToken)
        }

        guard let newNights, !newNights.isEmpty else {
            await MainActor.run { hasMore = false; isFetchingMore = false }
            return
        }

        let existingIDs = Set(gameNights.map { $0.id })
        let dedupedNights = newNights.filter { !existingIDs.contains($0.id) }
        guard !dedupedNights.isEmpty else {
            await MainActor.run { hasMore = false; isFetchingMore = false }
            return
        }
        gameNights.append(contentsOf: dedupedNights)
        offset += newNights.count

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchAllGameNightImages(for: newNights, accessToken: accessToken) }
            group.addTask { await self.fetchUserProfileImages(for: newNights, accessToken: accessToken) }
        }

        await prepareFinalModel()
        await MainActor.run { isFetchingMore = false }
    }

    func fetchAllGameNightImages(for nights: [GameNightModel], accessToken: String) async {
        let entries: [(id: Int, blob: String)] = nights.flatMap { night in
            (night.images ?? []).map { (night.id, $0) }
        }
        guard !entries.isEmpty else { return }

        let urls = (try? await imageService.getImageURLs(blobNames: entries.map { $0.blob }, accessToken: accessToken)) ?? []
        for (index, entry) in entries.enumerated() where index < urls.count {
            gameNightImageURLs[entry.id, default: []].append(urls[index])
        }
    }

    func fetchUserProfileImages(for nights: [GameNightModel], accessToken: String) async {
        var blobEntries: [(Int, String)] = []
        var seen = Set<Int>(userProfileImages.keys)
        for night in nights {
            for user in night.users {
                if let username = user.username {
                    usernames[user.id] = username
                }
                if let blob = user.profile_image_url, seen.insert(user.id).inserted {
                    blobEntries.append((user.id, blob))
                }
            }
        }
        guard !blobEntries.isEmpty else { return }

        let urls = (try? await imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)) ?? []
        for (index, (userID, _)) in blobEntries.enumerated() where index < urls.count {
            userProfileImages[userID] = urls[index]
        }
    }

    @MainActor
    func prepareFinalModel() async {
        gameNightPresent = gameNights.map { night in
            let winnerIDs = Set(night.sessions.flatMap { $0.winners_user_id }.compactMap { $0 })

            let players = night.users.map { user in
                PlayerFeedModel(
                    id: user.id,
                    username: user.username ?? "",
                    profileImageURL: userProfileImages[user.id],
                    isWinner: winnerIDs.contains(user.id)
                )
            }

            return GameNightFeedModel(
                id: night.id,
                hostUserID: night.host_user_id,
                hostUsername: usernames[night.host_user_id] ?? "",
                hostProfileImageURL: userProfileImages[night.host_user_id],
                date: night.game_night_date,
                description: night.description,
                photos: gameNightImageURLs[night.id] ?? [],
                players: players,
                sessions: night.sessions
            )
        }
    }
}
