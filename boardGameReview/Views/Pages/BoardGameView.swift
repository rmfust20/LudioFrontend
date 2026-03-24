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
    @StateObject private var boardGameViewModel: BoardGameViewModel

    init(boardGameID: Int) {
        self.boardGameID = boardGameID
        _boardGameViewModel = StateObject(wrappedValue: BoardGameViewModel(boardGameID: boardGameID))
    }

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // Hero image fading into background
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
                            await boardGameViewModel.getReviews()
                            await boardGameViewModel.getUserReview(userID: auth.userID ?? 0)
                        }
                    }

                    // Title + designers
                    VStack(alignment: .leading, spacing: 6) {
                        Text(boardGame?.name ?? "Loading...")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(.white)

                        Text(designers.joined(separator: ", "))
                            .font(.system(size: 13))
                            .foregroundStyle(Color("MutedText"))
                            .onAppear {
                                Task {
                                    designers = await boardGameViewModel.getBoardGameDesigners()
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // Metadata badges
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

                    // Rating
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
                            await boardGameViewModel.getReviewStats(boardGameID: boardGameID)
                        }
                    }

                    // Action row
                    HStack(spacing: 12) {
                        WantToPlayButtonView()
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)

                    // Rate + write review
                    RateThisGameFullView(id: boardGameID, rating: $boardGameViewModel.userRating)
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    // More info + Share
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color("MutedText"))
                            Text("More Info")
                                .font(.system(size: 11))
                                .foregroundStyle(Color("MutedText"))
                        }
                        Spacer()
                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(width: 1, height: 40)
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "arrowshape.turn.up.forward.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color("MutedText"))
                            Text("Share")
                                .font(.system(size: 11))
                                .foregroundStyle(Color("MutedText"))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 24)

                    // Reviews
                    if !boardGameViewModel.reviews.isEmpty {
                        HStack {
                            Text("Reviews")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 4)

                        Rectangle()
                            .fill(.white.opacity(0.08))
                            .frame(maxWidth: .infinity, maxHeight: 1)

                        LazyVStack(spacing: 0) {
                            ForEach(boardGameViewModel.reviews) { review in
                                Button {
                                    router.push(.profile(id: review.user_id))
                                } label: {
                                    ReviewCardView(reviewModel: review)
                                        .padding(.horizontal, 20)
                                }
                                .buttonStyle(.plain)

                                Rectangle()
                                    .fill(.white.opacity(0.06))
                                    .frame(maxWidth: .infinity, maxHeight: 1)
                            }
                        }
                    }

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .edgesIgnoringSafeArea(.top)
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
