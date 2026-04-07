//
//  HomeNavRootView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/13/25.
//

import SwiftUI

enum AppRoute: Hashable {
    case boardGame(id: Int)
    case addReview(id: Int, rating: Int?, review: ReviewModel?)
    case boardGameDetail(id: Int)
    case addGameNight(id: Int)
    case profile(id: Int, username: String)
    case gameNightFeed(userOnly : Int?)
    case gameNight(id: Int)
}

struct AppNavRouter<Root: View>: View {
    @Binding var selectedTab: Tab
    @StateObject private var router = AppRouter()
    let root: () -> Root

    var body: some View {
        NavigationStack(path: $router.path) {
            root()
                .environmentObject(router)
                // This ensures the back button doesn't carry the "Home" text forward
                .navigationDestination(for: AppRoute.self) { route in
                    viewForRoute(route)
                        .customNavBar(trailingTitle: trailingTitle(for: route))
                        // This removes the "Back" text and keeps only the arrow
                }
        }
        .environmentObject(router)
    }
    @ViewBuilder
    private func viewForRoute(_ route: AppRoute) -> some View {
        switch route {
        case .boardGame(let id):
            BoardGameView(boardGameID: id)
        case .addGameNight(let id):
            AddGameNightView(userID: id)
        case .addReview(let id, let rating, let review):
            AddReviewView(boardGameID: id, rating: rating ?? 0, review: review)
        case .boardGameDetail(let id):
            BoardGameDetailView(boardGameID: id)
        case .profile(let id, let username):
            ProfileView(userID: id, username: username)
        case .gameNightFeed(let userOnly):
            GameNightFeedView(userOnly: userOnly)
        case .gameNight(let id):
            GameNightDetailView(gameNightID: id)
        }
    }
}

private func trailingTitle(for route: AppRoute) -> Bool {
    switch route {
    case .addReview:
        return true
    case .addGameNight:
        return true
    default:
        return false
    }
}

