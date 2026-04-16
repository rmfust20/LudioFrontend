//
//  GameNightDetailViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/24/26.
//

import Foundation

class GameNightDetailViewModel: ObservableObject {
    private let gameNightService: GameNightService
    private let imageService: ImageService

    @Published var feedModel: GameNightFeedModel?

    init(gameNightService: GameNightService = GameNightService(), imageService: ImageService = ImageService()) {
        self.gameNightService = gameNightService
        self.imageService = imageService
    }

    @MainActor
    func fetchGameNight(id: Int, accessToken: String) async {
        guard let night = try? await gameNightService.getGameNight(id: id, accessToken: accessToken) else { return }

        let blobEntries: [(Int, String)] = night.users.compactMap { user in
            guard let blob = user.profile_image_url else { return nil }
            return (user.id, blob)
        }

        // Resolve profile images and game night photos in parallel
        let photoBlobs = night.images ?? []
        async let profileFetch = imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)
        async let photoFetch = imageService.getImageURLs(blobNames: photoBlobs, accessToken: accessToken)

        let profileURLMap = (try? await profileFetch) ?? [:]
        let photoURLMap = (try? await photoFetch) ?? [:]
        let photoURLs = photoBlobs.compactMap { photoURLMap[$0] }

        var userProfileImages: [Int: String] = [:]
        var usernames: [Int: String] = [:]

        for user in night.users {
            if let username = user.username {
                usernames[user.id] = username
            }
        }
        for (userID, blob) in blobEntries {
            if let url = profileURLMap[blob] {
                userProfileImages[userID] = url
            }
        }

        let winnerIDs = Set(night.sessions.flatMap { $0.winners_user_id }.compactMap { $0 })
        let players = night.users.map { user in
            PlayerFeedModel(
                id: user.id,
                username: user.username ?? "",
                profileImageURL: userProfileImages[user.id],
                isWinner: winnerIDs.contains(user.id)
            )
        }

        feedModel = GameNightFeedModel(
            id: night.id,
            hostUserID: night.host_user_id,
            hostUsername: usernames[night.host_user_id] ?? "",
            hostProfileImageURL: userProfileImages[night.host_user_id],
            date: night.game_night_date,
            description: night.description,
            photos: photoURLs,
            players: players,
            sessions: night.sessions
        )
    }
}
