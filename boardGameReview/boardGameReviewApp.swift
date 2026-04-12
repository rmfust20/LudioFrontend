//
//  boardGameReviewApp.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/6/25.
//

import SwiftUI

@main
struct boardGameReviewApp: App {
    @StateObject private var auth = Auth()
    @StateObject var userViewModel = UserViewModel()
    @StateObject var appRouter = AppRouter()
    @State private var isRestoringSession = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isRestoringSession {
                    ZStack {
                        Color("CharcoalBackground").ignoresSafeArea()
                        ProgressView().tint(.white)
                    }
                } else if auth.accessToken != nil {
                    BottomNavBarView()
                } else {
                    RegisterView()
                }
            }
            .environmentObject(auth)
            .environmentObject(userViewModel)
            .environmentObject(appRouter)
            .task {
                APIClient.shared.auth = auth
                await restoreSession()
                isRestoringSession = false
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
            .onChange(of: auth.accessToken) { newToken in
                guard newToken != nil else { return }
                Task { await processPendingInvite() }
            }
        }
    }

    private func restoreSession() async {
        guard let storedToken = auth.storedRefreshToken else { return }

        let storedUsername = UserDefaults.standard.string(forKey: "ludio_username") ?? ""
        let storedUserID   = UserDefaults.standard.integer(forKey: "ludio_user_id")

        guard let refreshed = try? await userViewModel.userService.refresh(refreshToken: storedToken) else {
            auth.clear()
            return
        }

        let fullResponse = AuthResponse(
            access_token:  refreshed.access_token,
            refresh_token: refreshed.refresh_token,
            token_type:    refreshed.token_type,
            user:          RegisterResponse(username: storedUsername, id: storedUserID)
        )
        await MainActor.run { auth.setSession(fullResponse) }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "tabulus",
              let host = url.host?.lowercased(),
              host == "invite",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let token = components.queryItems?.first(where: { $0.name == "token" })?.value
        else { return }

        if auth.accessToken != nil {
            // Already logged in — accept immediately
            Task { await processPendingInvite(token: token) }
        } else {
            // Not logged in — stash for after login/signup
            auth.pendingInviteToken = token
        }
    }

    private func processPendingInvite(token: String? = nil) async {
        let inviteToken = token ?? auth.pendingInviteToken
        guard let inviteToken, let accessToken = auth.accessToken else { return }

        await MainActor.run { auth.pendingInviteToken = nil }

        _ = try? await userViewModel.userService.acceptInvite(token: inviteToken, accessToken: accessToken)
    }
}
