//
//  BoardGameViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import Foundation
import UIKit

class BoardGameViewModel: ObservableObject {
    private let boardGameService: BoardGameService
    let boardGameID: Int
    @Published var boardGame : BoardGameModel? = nil
    @Published var boardGameImage : UIImage? = nil
    @Published var reviews: [ReviewModel] = []
    @Published var averageRating: Double? = nil
    @Published var numberOfRatings: Int? = nil
    @Published var numberOfReviews: Int? = nil
    @Published var userRating : Int = 0
    @Published var userReview : ReviewModel? = nil
    @Published var userWinRate: WinRateResponse? = nil
    @Published var reviewProfileImages: [Int: String] = [:]
    private let reviewService: ReviewService
    private let userService: UserService
    private let imageService: ImageService

    init(boardGameService: BoardGameService = BoardGameService(), reviewService: ReviewService = ReviewService(), userService: UserService = UserService(), imageService: ImageService = ImageService(), boardGameID: Int) {
        self.boardGameService = boardGameService
        self.reviewService = reviewService
        self.userService = userService
        self.imageService = imageService
        self.boardGameID = boardGameID
        print(boardGameID)
    }
    
    @MainActor
    func fetchBoardGame(_ boardGameID: Int, accessToken: String) async -> BoardGameModel? {
        let fetchedBoardGame = try? await boardGameService.fetchBoardGame(boardGameID: boardGameID, accessToken: accessToken)
        if let fetchedBoardGame = fetchedBoardGame {
            return fetchedBoardGame
        }
        else {
            return nil
        }
    }
    
    @MainActor
    func presentImage() async {
        let cachedImage = ImageCache.shared.getImage(for: boardGameID)
        if cachedImage == nil {
            let networkImage = try? await boardGameService.fetchBoardGameImage(boardGame?.image ?? "")
            if let networkImage = networkImage {
                //ID is always valid here because we were able to fetch the image from the network
                ImageCache.shared.storeImage(networkImage, for: boardGameID)
                self.boardGameImage = networkImage
            }
        }
        else {
            self.boardGameImage = cachedImage
        }
    }
    
    @MainActor
    func presentBoardGame(accessToken: String) async {
        let cachedBoardGame = BoardGameCache.shared.get(id: boardGameID)
        if cachedBoardGame == nil {
            let networkBoardGame = await fetchBoardGame(boardGameID, accessToken: accessToken)
            if let networkBoardGame = networkBoardGame {
                BoardGameCache.shared.set(networkBoardGame)
                self.boardGame = networkBoardGame
            }
        }
        else {
            self.boardGame = cachedBoardGame
        }
    }
    
    @MainActor
    func getBoardGameDesigners(accessToken: String) async -> [String] {
        let designers = try? await boardGameService.fetchBoardGameDesigners(boardGameID, accessToken: accessToken)
        return designers ?? []
    }

    @MainActor
    func getReviews(accessToken: String) async {
        guard let fetchedReviews = try? await reviewService.getReviews(boardGameID: boardGameID, accessToken: accessToken) else { return }
        reviews = fetchedReviews

        let userIDs = Array(Set(fetchedReviews.map { $0.user_id }))
        let profiles = (try? await userService.getUsers(userIDs: userIDs, accessToken: accessToken)) ?? []

        let blobEntries: [(Int, String)] = profiles.compactMap { p in
            guard let blob = p.profile_image_url else { return nil }
            return (p.id, blob)
        }
        let urls = (try? await imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)) ?? []
        for (index, (userID, _)) in blobEntries.enumerated() where index < urls.count {
            reviewProfileImages[userID] = urls[index]
        }
    }

    @MainActor
    func getReviewStats(boardGameID: Int, accessToken: String) async {
        if let stats = try? await reviewService.getReviewStats(boardGameID: boardGameID, accessToken: accessToken) {
            averageRating = stats.average_rating
            numberOfRatings = stats.number_of_ratings
            numberOfReviews = stats.number_of_reviews
        }
    }

    @MainActor
    func getUserReview(userID: Int, accessToken: String) async {
        if let review = try? await reviewService.getUserReview(boardGameID: boardGameID, userID: userID, accessToken: accessToken) {
            userRating = review.rating
            userReview = review
        }
    }
    
    func updateReview(reviewID: Int, review: ReviewUpdate, accessToken: String) async throws {
        try await reviewService.updateReview(reviewID: reviewID, update: review, accessToken: accessToken)
    }
    
    func deleteReview(reviewID: Int, accessToken: String) async throws {
        try await reviewService.deleteReview(reviewID: reviewID, accessToken: accessToken)
    }

    @MainActor
    func getWinRateForGame(userID: Int, accessToken: String) async {
        userWinRate = try? await userService.getWinRateForGame(userID: userID, boardGameID: boardGameID, accessToken: accessToken)
    }
}
