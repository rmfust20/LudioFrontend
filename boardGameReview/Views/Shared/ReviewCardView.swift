import SwiftUI

struct ReviewCardView: View {
    let reviewModel: ReviewModel
    let profileImageURL: String?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let url = profileImageURL {
                    AsyncImage(url: URL(string: url)) { image in
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

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(reviewModel.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("rated it")
                        .font(.system(size: 13))
                        .foregroundStyle(Color("MutedText"))

                    FlexStarsView(rating: .constant(reviewModel.rating), size: 12, interactive: false)
                }

                Text(reviewModel.comment ?? "")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    ReviewCardView(
        reviewModel: ReviewModel(id: 0, board_game_id: 0, user_id: 0, username: "rmfust50", rating: 4, comment: "Great game!"),
        profileImageURL: nil
    )
    .background(Color("CardSurface"))
}
