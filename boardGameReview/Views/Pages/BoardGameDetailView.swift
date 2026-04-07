//
//  BoardGameDetailView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/25/26.
//

import SwiftUI

struct BoardGameDetailView: View {
    let boardGameID: Int
    @EnvironmentObject var auth: Auth
    @EnvironmentObject var router: AppRouter
    @State private var cardImage: UIImage? = nil
    @State private var boardGame: BoardGameModel? = nil
    @State private var designers: [String] = []
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

                    // Hero image
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
                            designers = await boardGameViewModel.getBoardGameDesigners(accessToken: auth.accessToken ?? "")
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)

                    // Metadata badges
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            if let min = boardGame?.min_players, let max = boardGame?.max_players {
                                DetailStatBadge(icon: "person.2.fill", label: "\(min)–\(max) players")
                            }
                            if let time = boardGame?.play_time, time > 0 {
                                DetailStatBadge(icon: "clock.fill", label: "\(time) min")
                            }
                            if let age = boardGame?.min_age {
                                DetailStatBadge(icon: "person.fill.checkmark", label: "Age \(age)+")
                            }
                            if let year = boardGame?.year_published {
                                DetailStatBadge(icon: "calendar", label: "\(year)")
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 14)

                    // Description
                    if let description = boardGame?.description, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(description)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.75))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
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

private struct DetailStatBadge: View {
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
    BoardGameDetailView(boardGameID: 181)
        .environmentObject(Auth())
        .environmentObject(AppRouter())
}
