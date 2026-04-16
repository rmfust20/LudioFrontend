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
    @State private var showBGGRedirect: Bool = false
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
        VStack(spacing: 0) {
            Button {
                showBGGRedirect = true
            } label: {
                Image("bggIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, -30)
                    .padding(.bottom, -30)
            }
            .background(Color(red: 0.11, green: 0.11, blue: 0.12))
            .alert("Leave App?", isPresented: $showBGGRedirect) {
                Button("Go to BoardGameGeek") {
                    if let url = URL(string: "https://boardgamegeek.com") {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You will be redirected to boardgamegeek.com")
            }

            TabView(selection: $selectedTab) {

                AppNavRouter(selectedTab: $selectedTab) { GameNightFeedView(userOnly: nil) }
                    .tabItem { Label("Game", systemImage: "envelope.front.fill") }
                    .tag(Tab.game)

                AppNavRouter(selectedTab: $selectedTab) { HomeView() }
                .tabItem { Label("Home", systemImage: "house") }
                .tag(Tab.home)

                AppNavRouter(selectedTab: $selectedTab) { ProfileView(userID: auth.userID ?? 0, username: auth.username) }
                        .tabItem { Label("Profile", systemImage: "person") }
                        .tag(Tab.profile)

            }
            .tint(.black)
        }
    }
}

#Preview {
    BottomNavBarView()
}
