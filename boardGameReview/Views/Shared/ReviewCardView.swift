import SwiftUI

struct ReviewCardView: View {
    @EnvironmentObject var auth: Auth
    let reviewModel: ReviewPublicModel
    let profileImageURL: String?
    let onReport: () -> Void
    @State private var showReportConfirmation = false

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
                    Text(reviewModel.user.username ?? "Unknown User")
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
            Spacer(minLength: 0)
            if reviewModel.user.id != auth.userID {
                Button {
                    showReportConfirmation = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(Color("MutedText"))
                        .padding(8)
                }
                .confirmationDialog("Report this review?", isPresented: $showReportConfirmation, titleVisibility: .visible) {
                    Button("Report", role: .destructive) {
                        onReport()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(.vertical, 14)
    }
}


