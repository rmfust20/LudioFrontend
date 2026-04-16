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
    @Published var reviews: [ReviewPublicModel] = []
    @Published var averageRating: Double? = nil
    @Published var numberOfRatings: Int? = nil
    @Published var numberOfReviews: Int? = nil
    @Published var userRating : Int = 0
    @Published var userReview : ReviewModel? = nil
    @Published var userWinRate: WinRateResponse? = nil
    @Published var reviewProfileImages: [Int: String] = [:]
    @Published var isLoadingReviews = false
    @Published var reviewsOffset = 0
    @Published var pinnedReview: ReviewPublicModel? = nil
    private let reviewService: ReviewService
    private let userService: UserService
    private let imageService: ImageService

    init(boardGameService: BoardGameService = BoardGameService(), reviewService: ReviewService = ReviewService(), userService: UserService = UserService(), imageService: ImageService = ImageService(), boardGameID: Int) {
        self.boardGameService = boardGameService
        self.reviewService = reviewService
        self.userService = userService
        self.imageService = imageService
        self.boardGameID = boardGameID
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
        isLoadingReviews = true
        let fetched = (try? await reviewService.getReviews(boardGameID: boardGameID, offset: reviewsOffset, accessToken: accessToken)) ?? []
        let newReviews = fetched.filter { r in !reviews.contains(where: { $0.id == r.id }) }
        reviews.append(contentsOf: newReviews)
        reviewsOffset += fetched.count

        await fetchReviewProfileImages(for: newReviews, accessToken: accessToken)
        isLoadingReviews = false
    }

    @MainActor
    func fetchReviewProfileImages(for reviews: [ReviewPublicModel], accessToken: String) async {
        let knownIDs = Set(reviewProfileImages.keys)
        var seen = Set<Int>()
        let blobEntries: [(Int, String)] = reviews.compactMap { r in
            guard !knownIDs.contains(r.user.id), seen.insert(r.user.id).inserted,
                  let blob = r.user.profile_image_url else { return nil }
            return (r.user.id, blob)
        }
        guard !blobEntries.isEmpty else { return }

        let urlMap = (try? await imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)) ?? [:]
        for (userID, blob) in blobEntries {
            if let url = urlMap[blob] {
                reviewProfileImages[userID] = url
            }
        }
    }

    @MainActor
    func resetReviews() {
        reviews = []
        reviewProfileImages = [:]
        reviewsOffset = 0
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
    
    @MainActor
    func getPinnedReview(userID: Int, accessToken: String) async {
        if let review = try? await reviewService.getPinnedReview(boardGameID: boardGameID, userID: userID, accessToken: accessToken) {
            pinnedReview = review
            await fetchReviewProfileImages(for: [review], accessToken: accessToken)
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
