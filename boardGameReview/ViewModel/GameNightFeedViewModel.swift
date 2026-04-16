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
    @Published var isLoading = false
    var gameNights: [GameNightModel] = []
    var gameNightImageURLs: [Int: [String]] = [:]
    var userProfileImages: [Int: String] = [:]
    @Published var offset = 0
    
    //gameNightImageURLs is a dict with key of id that maps to all of its images
    //userProfileImages is a dict with key of user id that maps to the profile image url
    
    //I should probably just have it fetching from an image cache right?? that way we can cook
    //all we need is a profileImageCache and gameNightImageCahce
    
    

    init(gameNightService: GameNightService = GameNightService(), imageService: ImageService = ImageService()) {
        self.gameNightService = gameNightService
        self.imageService = imageService
    }

    @MainActor
    func fetchGameNights(userID: Int, accessToken: String) async {
        isLoading = true
        let nights = try? await gameNightService.getGameNightFeed(userID: userID, offset: offset, accessToken: accessToken)
        if let nights {
            let newNights = nights.filter { n in !gameNights.contains(where: { $0.id == n.id }) }
            gameNights.append(contentsOf: newNights)
            offset += nights.count
        }
    }


    @MainActor
    func fetchUserGameNights(userID: Int, accessToken: String) async {
        isLoading = true
        let nights = try? await gameNightService.getUserGameNights(userID: userID, offset: offset, accessToken: accessToken)
        if let nights {
            let newNights = nights.filter { n in !gameNights.contains(where: { $0.id == n.id }) }
            gameNights.append(contentsOf: newNights)
            offset += nights.count
        }
    }

    @MainActor
    func fetchAllGameNightImages(for nights: [GameNightModel], accessToken: String) async {
        let entries: [(id: Int, blob: String)] = nights.flatMap { night in
            (night.images ?? []).map { (night.id, $0) }
        }
        guard !entries.isEmpty else { return }

        let urlMap = (try? await imageService.getImageURLs(blobNames: entries.map { $0.blob }, accessToken: accessToken)) ?? [:]
        var grouped: [Int: [String]] = [:]
        for entry in entries {
            if let url = urlMap[entry.blob] {
                grouped[entry.id, default: []].append(url)
            }
        }
        for (nightID, nightURLs) in grouped {
            gameNightImageURLs[nightID] = nightURLs
        }
    }

    @MainActor
    func fetchUserProfileImages(for nights: [GameNightModel], accessToken: String) async {
        var blobEntries: [(Int, String)] = []
        var seen = Set<Int>(userProfileImages.keys)
        for night in nights {
            for user in night.users {
                if let blob = user.profile_image_url, seen.insert(user.id).inserted {
                    blobEntries.append((user.id, blob))
                }
            }
        }
        guard !blobEntries.isEmpty else { return }

        let urlMap = (try? await imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)) ?? [:]
        for (userID, blob) in blobEntries {
            if let url = urlMap[blob] {
                userProfileImages[userID] = url
            }
        }
    }

    @MainActor
    func prepareFinalModel() async {
        let existingIDs = Set(gameNightPresent.map { $0.id })
        let newNights = gameNights
            .filter { !existingIDs.contains($0.id) }
            .sorted { $0.id > $1.id }

        let newModels = newNights.map { night in
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
                hostUsername: night.users.first(where: { $0.id == night.host_user_id })?.username ?? "",
                hostProfileImageURL: userProfileImages[night.host_user_id],
                date: night.game_night_date,
                description: night.description,
                photos: gameNightImageURLs[night.id] ?? [],
                players: players,
                sessions: night.sessions
            )
        }

        gameNightPresent.append(contentsOf: newModels)
        isLoading = false
    }
    
 
    @MainActor
    func removeGameNight(id: Int) {
        gameNightPresent.removeAll { $0.id == id }
        gameNights.removeAll { $0.id == id }
        gameNightImageURLs.removeValue(forKey: id)
    }

    @MainActor
    func reset() async {
        gameNightPresent = []
        gameNights = []
        gameNightImageURLs = [:]
        userProfileImages = [:]
        offset = 0
    }

    @MainActor
    func fetchMoreGameNights(userID: Int, accessToken: String, userOnly: Int?) async {
        if let userOnly = userOnly {
            await fetchUserGameNights(userID: userOnly, accessToken: accessToken)
        } else {
            await fetchGameNights(userID: userID, accessToken: accessToken)
        }
        async let images: () = fetchAllGameNightImages(for: gameNights, accessToken: accessToken)
        async let profiles: () = fetchUserProfileImages(for: gameNights, accessToken: accessToken)
        await images
        await profiles
        await prepareFinalModel()
    }
}
