import SwiftUI

struct RateThisGameFullView: View {
    @EnvironmentObject private var router: AppRouter// 0 means “no rating yet”
    @StateObject private var reviewViewModel = ReviewViewModel()
    @EnvironmentObject private var auth : Auth
    let id : Int
    @Binding var rating: Int
    let review: ReviewModel?
    let onNavigateToReview: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Rate This Game:")
                .foregroundStyle(.gray)
            FlexStarsView(rating:$rating, size: 24, interactive: true)
        }
        .padding()
        .onDisappear {
            Task {
                do {
                    if let existing = review, let reviewID = existing.id {
                        if rating == 0 && existing.comment == nil {
                            // No rating and no comment — delete the review
                            try await reviewViewModel.deleteReview(
                                reviewID: reviewID,
                                accessToken: auth.accessToken ?? ""
                            )
                        } else if rating > 0 && rating != existing.rating {
                            // Rating changed — update it
                            try await reviewViewModel.updateReview(
                                reviewID: reviewID,
                                review: ReviewUpdate(id: reviewID, rating: rating),
                                accessToken: auth.accessToken ?? ""
                            )
                        }
                    }
                } catch {
                    print("Error saving review: \(error)")
                }
            }
        }

        if rating > 0 && review != nil {
            ReviewButton(id: id, rating: rating, review: review, text: "Edit your review", onNavigate: onNavigateToReview)
        } else if rating > 0 && review == nil {
            ReviewButton(id: id, rating: rating, review: nil, text: "Write a review", onNavigate: onNavigateToReview)
        }
           
    }
    
}

struct Stars : View {
    @Binding var rating: Int
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<5) { index in
                Button {
                    let newRating = index + 1
                    rating = (rating == newRating) ? 0 : newRating
                    //TODO network call to update users ratings
                } label: {
                    Image(systemName: index < rating ? "star.fill" : "star")
                        .font(.title)
                        .foregroundStyle(index < rating ? .yellow : .gray)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Rate \(index + 1) star\(index == 0 ? "" : "s")")
            }
        }
    }
}


