import SwiftUI

struct RetryAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let maxRetries: Int
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var attempt = 0

    init(
        url: URL?,
        maxRetries: Int = 2,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.maxRetries = maxRetries
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                content(image)
            case .failure:
                placeholder()
                    .onAppear {
                        if attempt < maxRetries {
                            attempt += 1
                        }
                    }
            default:
                placeholder()
            }
        }
        .id(attempt)
    }
}
