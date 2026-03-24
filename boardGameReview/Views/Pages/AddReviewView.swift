//
//  AddReviewView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 1/4/26.
//

import SwiftUI

struct AddReviewView: View {
    let boardGameID: Int
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: Auth
    @State var rating: Int
    @State private var text: String = ""
    @StateObject private var reviewViewModel = ReviewViewModel()

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            VStack(spacing: 16) {
                // Rating card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Rating")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("MutedText"))
                        .tracking(0.5)
                    FlexStarsView(rating: $rating, size: 30, interactive: true)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("CardSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 4)

                // Review text card
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Review")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color("MutedText"))
                        .tracking(0.5)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $text)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .foregroundStyle(.white)
                            .frame(minHeight: 160)
                        if text.isEmpty {
                            Text("Write your review here...")
                                .foregroundStyle(Color("MutedText"))
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(20)
                .background(Color("CardSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 4)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Post") {
                    Task {
                        let reviewModel = ReviewModel(
                            id: nil,
                            board_game_id: boardGameID,
                            user_id: auth.userID ?? 0,
                            username: auth.username ?? "unknown",
                            rating: rating,
                            comment: text
                        )

                        do {
                            try await reviewViewModel.postReview(reviewModel, accessToken: auth.accessToken ?? "")
                            router.pop()
                        } catch {
                            print("Error posting review: \(error)")
                        }
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color("PrimaryButton"))
            }
        }
    }
}

#Preview {
    AddReviewView(boardGameID: 0, rating: 0)
}
