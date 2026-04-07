//
//  GameNightDetailView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/24/26.
//

import SwiftUI

struct GameNightDetailView: View {
    let gameNightID: Int
    @EnvironmentObject private var auth: Auth
    @StateObject private var viewModel = GameNightDetailViewModel()
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    HStack {
                        Text("Game Night")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)

                    if let feedModel = viewModel.feedModel {
                        GameNightCardView(gameNight: feedModel)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 32)
            }
        }
        .overlay {
            if isLoading {
                Color("CharcoalBackground").ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .task {
            await viewModel.fetchGameNight(id: gameNightID, accessToken: auth.accessToken ?? "")
            isLoading = false
        }
    }
}

#Preview {
    GameNightDetailView(gameNightID: 1)
        .environmentObject(Auth())
        .environmentObject(AppRouter())
}
