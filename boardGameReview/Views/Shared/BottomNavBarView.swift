//
//  BottomNavBarView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/12/25.
//

import SwiftUI

enum Tab: Hashable {
    case home, profile, login, game
}

struct BottomNavBarView: View {
    @State private var selectedTab: Tab = .home
    @EnvironmentObject private var auth: Auth

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1)
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor.white
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor.white]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {

                AppNavRouter(selectedTab: $selectedTab) { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

                AppNavRouter(selectedTab: $selectedTab) { ProfileView(userID: auth.userID ?? 0) }
                    .tabItem { Label("Profile", systemImage: "person") }
                    .tag(Tab.profile)
            AppNavRouter(selectedTab: $selectedTab) { RegisterView(userID: 0) }
                .tabItem { Label("Login", systemImage: "square.and.arrow.up") }
                .tag(Tab.login)
            
            AppNavRouter(selectedTab: $selectedTab) { GameNightFeedView(userOnly: false) }
                .tabItem { Label("Game", systemImage: "calendar") }
                .tag(Tab.game)
                
        }
        .tint(.white)
    }
}

#Preview {
    BottomNavBarView()
}
