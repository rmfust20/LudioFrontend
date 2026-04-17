import SwiftUI

struct ReviewCardView: View {
    @EnvironmentObject var auth: Auth
    let reviewModel: ReviewPublicModel
    let profileImageURL: String?
    let onReport: () -> Void
    let onBlock: () -> Void
    @State private var showOptions = false
    @State private var showReportConfirmation = false
    @State private var showBlockConfirmation = false
    @State private var isExpanded = false
    @State private var isTruncated = false
    @State private var fullTextHeight: CGFloat? = nil
    @State private var clampedTextHeight: CGFloat? = nil
    private let collapsedLineLimit = 3

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let url = profileImageURL {
                    RetryAsyncImage(url: URL(string: url)) { image in
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
                
                let comment = reviewModel.comment ?? ""
                Text(comment)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(isExpanded ? nil : collapsedLineLimit)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(
                        Text(comment)
                            .font(.system(size: 14))
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .background(GeometryReader { full in
                                Color.clear.preference(
                                    key: ReviewTextHeightKey.self,
                                    value: full.size.height
                                )
                            })
                    )
                    .background(
                        Text(comment)
                            .font(.system(size: 14))
                            .lineLimit(collapsedLineLimit)
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .background(GeometryReader { clamped in
                                Color.clear.preference(
                                    key: ReviewClampedHeightKey.self,
                                    value: clamped.size.height
                                )
                            })
                    )
                    .onPreferenceChange(ReviewTextHeightKey.self) { fullHeight in
                        evaluateTruncation(fullHeight: fullHeight, clampedHeight: nil)
                    }
                    .onPreferenceChange(ReviewClampedHeightKey.self) { clampedHeight in
                        evaluateTruncation(fullHeight: nil, clampedHeight: clampedHeight)
                    }

                if isTruncated {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        Text(isExpanded ? "See less" : "See more")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color("MutedText"))
                    }
                }
            }
            Spacer(minLength: 0)
            if reviewModel.user.id != auth.userID {
                Button {
                    showOptions = true
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16))
                        .foregroundStyle(Color("MutedText"))
                        .padding(8)
                }
                .confirmationDialog("", isPresented: $showOptions) {
                    Button("Report", role: .destructive) {
                        showReportConfirmation = true
                    }
                    Button("Block", role: .destructive) {
                        showBlockConfirmation = true
                    }
                    Button("Cancel", role: .cancel) {}
                }
                .alert("Report this review?", isPresented: $showReportConfirmation) {
                    Button("Report", role: .destructive) { onReport() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("This review will be reported for review.")
                }
                .alert("Block \(reviewModel.user.username ?? "this user")?", isPresented: $showBlockConfirmation) {
                    Button("Block", role: .destructive) { onBlock() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("You won't see their reviews or game nights anymore.")
                }
            }
        }
        .padding(.vertical, 14)
    }

    private func evaluateTruncation(fullHeight: CGFloat?, clampedHeight: CGFloat?) {
        if let full = fullHeight {
            fullTextHeight = full
        }
        if let clamped = clampedHeight {
            clampedTextHeight = clamped
        }
        guard let full = fullTextHeight, let clamped = clampedTextHeight else { return }
        let shouldTruncate = full > clamped + 0.5
        if shouldTruncate != isTruncated {
            isTruncated = shouldTruncate
        }
    }
}

private struct ReviewTextHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct ReviewClampedHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


