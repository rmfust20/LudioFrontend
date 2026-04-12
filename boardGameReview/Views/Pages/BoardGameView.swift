//
//  BoardGameView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/12/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct BoardGameView: View {
    let boardGameID: Int
    @EnvironmentObject var auth: Auth
    @EnvironmentObject var router: AppRouter
    @State var cardImage: UIImage? = nil
    @State var boardGame: BoardGameModel? = nil
    @State var designers: [String] = []
    @State private var showDeleteConfirmation = false
    @State private var isNavigatingToAddReview = false
    @State private var isDescriptionExpanded = false
    @State private var isLoading = false
    @StateObject private var boardGameViewModel: BoardGameViewModel
    @StateObject private var reviewViewModel = ReviewViewModel()

    init(boardGameID: Int) {
        self.boardGameID = boardGameID
        _boardGameViewModel = StateObject(wrappedValue: BoardGameViewModel(boardGameID: boardGameID))
    }
    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    heroSection
                    titleSection
                    badgesSection
                    ratingSection
                    winRateSection
                    descriptionSection
                    rateSection
                    deleteReviewSection
                    reviewsSection
                    Color.clear.frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .overlay {
            if isLoading {
                Color("CharcoalBackground").ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onDisappear(perform: handleDisappear)
        .onChange(of: router.reviewPosted) {
            if router.reviewPosted {
                router.reviewPosted = false
                Task {
                    boardGameViewModel.resetReviews()
                    boardGameViewModel.pinnedReview = nil
                    await boardGameViewModel.getPinnedReview(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                    await boardGameViewModel.getReviews(accessToken: auth.accessToken ?? "")
                    await boardGameViewModel.getReviewStats(boardGameID: boardGameID, accessToken: auth.accessToken ?? "")
                    await boardGameViewModel.getUserReview(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                }
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            if let image = cardImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: UIScreen.main.bounds.width, height: 360)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.12))
                    .frame(width: UIScreen.main.bounds.width, height: 360)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 52))
                            .foregroundStyle(Color.gray.opacity(0.25))
                    )
            }
            LinearGradient(
                colors: [Color("CharcoalBackground").opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .init(x: 0.5, y: 0.25)
            )
            .frame(width: UIScreen.main.bounds.width, height: 360)
            LinearGradient(
                colors: [.clear, Color("CharcoalBackground")],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(width: UIScreen.main.bounds.width, height: 360)
        }
        .onAppear {
            Task {
                await boardGameViewModel.presentBoardGame(accessToken: auth.accessToken ?? "")
                await boardGameViewModel.presentImage()
                boardGame = boardGameViewModel.boardGame
                cardImage = boardGameViewModel.boardGameImage
                isLoading = false
                await boardGameViewModel.getPinnedReview(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                await boardGameViewModel.getReviews(accessToken: auth.accessToken ?? "")
                await boardGameViewModel.getUserReview(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                await boardGameViewModel.getWinRateForGame(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
            }
        }
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(boardGame?.name ?? "Loading...")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)

            Text(designers.joined(separator: ", "))
                .font(.system(size: 13))
                .foregroundStyle(Color("MutedText"))
                .onAppear {
                    Task {
                        designers = await boardGameViewModel.getBoardGameDesigners(accessToken: auth.accessToken ?? "")
                    }
                }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var badgesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                if let min = boardGame?.min_players, let max = boardGame?.max_players {
                    StatBadge(icon: "person.2.fill", label: "\(min)–\(max) players")
                }
                if let time = boardGame?.play_time, time > 0 {
                    StatBadge(icon: "clock.fill", label: "\(time) min")
                }
                if let age = boardGame?.min_age {
                    StatBadge(icon: "person.fill.checkmark", label: "Age \(age)+")
                }
                if let year = boardGame?.year_published {
                    StatBadge(icon: "calendar", label: "\(year)")
                }
            }
            .padding(.leading, 20)
            .padding(.trailing, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 14)
    }

    @ViewBuilder
    private var ratingSection: some View {
        HStack {
            ComputedRatingView(
                averageRating: boardGameViewModel.averageRating,
                numberOfRatings: boardGameViewModel.numberOfRatings,
                numberOfReviews: boardGameViewModel.numberOfReviews
            )
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .onAppear {
            Task {
                await boardGameViewModel.getReviewStats(boardGameID: boardGameID, accessToken: auth.accessToken ?? "")
            }
        }
    }

    @ViewBuilder
    private var winRateSection: some View {
        if let wr = boardGameViewModel.userWinRate, wr.total_sessions > 0 {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("PrimaryButton"))
                Text("Your Win Rate:")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
                Text("\(Int(wr.win_rate * 100))%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text("(\(wr.wins)/\(wr.total_sessions) sessions)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("MutedText"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 10)
        }
    }

    @ViewBuilder
    private var descriptionSection: some View {
        if let description = boardGame?.description, !description.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(isDescriptionExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isDescriptionExpanded.toggle()
                    }
                } label: {
                    Text(isDescriptionExpanded ? "See Less" : "See More")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("PrimaryButton"))
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private var rateSection: some View {
        RateThisGameFullView(
            id: boardGameID,
            rating: $boardGameViewModel.userRating,
            review: boardGameViewModel.userReview,
            onNavigateToReview: { isNavigatingToAddReview = true }
        )
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    @ViewBuilder
    private var deleteReviewSection: some View {
        if boardGameViewModel.userReview?.comment != nil {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Text("Delete this review")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.red)
            }
            .padding(.top, 6)
            .confirmationDialog(
                "Are you sure you want to delete your review?",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        if let review = boardGameViewModel.userReview, let reviewID = review.id {
                            try? await boardGameViewModel.deleteReview(reviewID: reviewID, accessToken: auth.accessToken ?? "")
                            boardGameViewModel.userReview = nil
                            boardGameViewModel.userRating = 0
                            boardGameViewModel.resetReviews()
                            boardGameViewModel.pinnedReview = nil
                            await boardGameViewModel.getPinnedReview(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                            await boardGameViewModel.getReviews(accessToken: auth.accessToken ?? "")
                            await boardGameViewModel.getReviewStats(boardGameID: boardGameID, accessToken: auth.accessToken ?? "")
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    @ViewBuilder
    private var reviewsSection: some View {
        if !boardGameViewModel.reviews.isEmpty || boardGameViewModel.pinnedReview != nil {
            HStack {
                Text("Reviews")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical)

            Rectangle()
                .fill(.white.opacity(0.08))
                .frame(maxWidth: .infinity, maxHeight: 1)

            ReviewsList(
                reviews: boardGameViewModel.reviews,
                pinnedReview: boardGameViewModel.pinnedReview,
                profileImages: boardGameViewModel.reviewProfileImages,
                isLoading: boardGameViewModel.isLoadingReviews,
                onTapUser: { userID, username in
                    router.push(.profile(id: userID, username: username))
                },
                onReport: { reviewID in
                    Task {
                        try? await reviewViewModel.reportReview(reviewID: reviewID, accessToken: auth.accessToken ?? "")
                    }
                },
                onReachEnd: {
                    Task {
                        await boardGameViewModel.getReviews(accessToken: auth.accessToken ?? "")
                    }
                }
            )
        }
    }

    private func handleDisappear() {
        guard !isNavigatingToAddReview else {
            isNavigatingToAddReview = false
            return
        }
        guard boardGameViewModel.userReview == nil && boardGameViewModel.userRating > 0 else { return }
        Task {
            let reviewModel = ReviewModel(
                id: nil,
                board_game_id: boardGameID,
                user_id: auth.userID ?? 0,
                username: auth.username ?? "unknown",
                rating: boardGameViewModel.userRating,
                comment: nil
            )
            try? await reviewViewModel.postReview(reviewModel, accessToken: auth.accessToken ?? "")
        }
    }
}

// MARK: - Reviews List

private struct ReviewsList: View {
    let reviews: [ReviewPublicModel]
    let pinnedReview: ReviewPublicModel?
    let profileImages: [Int: String]
    let isLoading: Bool
    let onTapUser: (Int, String) -> Void
    let onReport: (Int) -> Void
    let onReachEnd: () -> Void

    private var feedReviews: [ReviewPublicModel] {
        guard let pinnedID = pinnedReview?.id else { return reviews }
        return reviews.filter { $0.id != pinnedID }
    }

    var body: some View {
        Group {
            if let pinned = pinnedReview {
                Button {
                    onTapUser(pinned.user.id, pinned.user.username ?? "")
                } label: {
                    ReviewCardView(
                        reviewModel: pinned,
                        profileImageURL: profileImages[pinned.user.id],
                        onReport: { onReport(pinned.id) }
                    )
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(maxWidth: .infinity, maxHeight: 1)
            }

            ForEach(feedReviews) { review in
                Button {
                    onTapUser(review.user.id, review.user.username ?? "")
                } label: {
                    ReviewCardView(
                        reviewModel: review,
                        profileImageURL: profileImages[review.user.id],
                        onReport: { onReport(review.id) }
                    )
                    .padding(.horizontal, 20)
                }
                .buttonStyle(.plain)

                Rectangle()
                    .fill(.white.opacity(0.06))
                    .frame(maxWidth: .infinity, maxHeight: 1)
            }

            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }

            Color.clear
                .frame(height: 1)
                .onAppear {
                    if !isLoading && reviews.count >= 2 {
                        onReachEnd()
                    }
                }
        }
    }
}

// MARK: - Stat Badge

private struct StatBadge: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(label)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundStyle(Color("MutedText"))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.white.opacity(0.07))
        .clipShape(Capsule())
    }
}

#Preview {
    BoardGameView(boardGameID: 181)
        .environmentObject(Auth())
        .environmentObject(AppRouter())
}
