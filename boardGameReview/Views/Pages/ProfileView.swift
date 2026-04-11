//
//  ProfileView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/13/25.
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @StateObject var profileViewModel = ProfileViewModel()
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: Auth
    @State private var addFriendsPresented: Bool = false
    @State private var showAccountOptions: Bool = false
    @State private var showLogoutConfirm: Bool = false
    @State private var showDeleteConfirm: Bool = false
    @State private var isLoadingContent: Bool = true
    let userID: Int
    let username: String?

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    if userID == auth.userID {
                    Button {
                        showAccountOptions = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.horizontal, 20)
                    .padding(.bottom, -20)
                    .confirmationDialog("Account", isPresented: $showAccountOptions) {
                        Button("Log Out") { showLogoutConfirm = true }
                        Button("Delete Account", role: .destructive) { showDeleteConfirm = true }
                        Button("Cancel", role: .cancel) {}
                    }
                    .alert("Log Out?", isPresented: $showLogoutConfirm) {
                        Button("Log Out", role: .destructive) {
                            Task { await profileViewModel.logout(auth: auth) }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("Are you sure you want to log out?")
                    }
                    .alert("Delete Account?", isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) {
                            Task { await profileViewModel.deleteAccount(auth: auth) }
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently delete your account and all your data. This cannot be undone.")
                    }
                    }
                    // Header
                    HStack(alignment: .center) {
                        Text(username ?? "Loading...")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        if userID != auth.userID{
                            if !profileViewModel.userFriends.contains(where: { $0.id == auth.userID ?? 0 }) && !profileViewModel.pendingFriends.contains(where: { $0.id == auth.userID ?? 0 })
                            {
                                if !profileViewModel.sentFriendRequestIDs.contains(userID) {
                                    Button {
                                        Task {
                                            await profileViewModel.sendFriendRequest(userID: auth.userID ?? 0, friendID: userID, auth: auth)
                                        }
                                    } label: {
                                        Text("Add Friend")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(Color("PrimaryButton"))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

                    // Profile card
                    HStack(alignment: .center, spacing: 24) {
                        if userID == auth.userID {
                            PhotosPicker(
                                selection: $profileViewModel.selectedItem,
                                maxSelectionCount: 1,
                                matching: .images
                            ) {
                                profileAvatar
                            }
                            .buttonStyle(.plain)
                            .tint(.blue)
                            .onChange(of: profileViewModel.selectedItem) { _, _ in
                                Task {
                                    await profileViewModel.handleImageChange(auth: auth)
                                }
                            }
                        } else {
                            profileAvatar
                        }

                        Spacer()

                        ProfileStatBadge(value: String(profileViewModel.gameNights.count), label: "Posts")

                        Button {
                            addFriendsPresented.toggle()
                        } label: {
                            ProfileStatBadge(value: String(profileViewModel.userFriends.count), label: "Friends")
                                .overlay(alignment: .topTrailing) {
                                    if profileViewModel.userFriends.count == 0 && userID == auth.userID{
                                        Text("add")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Color.red)
                                            .clipShape(Capsule())
                                            .offset(x: 10, y: -6)
                                    } else if profileViewModel.pendingFriends.count > 0 && userID == auth.userID {
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 9, height: 9)
                                            .offset(x: 4, y: -2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)

                        ProfileStatBadge(value: String(profileViewModel.boardGames.count), label: "Games")
                    }
                    .padding(20)
                    .background(Color("CardSurface").opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.09), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, 16)

                    // Game Nights section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Game Nights")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if userID == auth.userID || profileViewModel.userFriends.contains(where: { $0.id == auth.userID ?? 0 }) {
                                Button {
                                    router.push(.gameNightFeed(userOnly: userID))
                                } label: {
                                    Text("See All")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Color("PrimaryButton"))
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        gameNightImageGrid
                            .padding(.horizontal, 16)
                    }

                    // Games section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Games")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(.white)
                            Spacer()
                            if let winRate = profileViewModel.winRate {
                                Text("Avg Win Rate: \(Int(winRate * 100))%")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color("MutedText"))
                            }
                        }
                        .padding(.horizontal, 20)

                        if profileViewModel.boardGames.isEmpty && !isLoadingContent {
                            VStack(spacing: 10) {
                                Image(systemName: "gamecontroller.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(Color("MutedText"))
                                Text("No games yet")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Text("Games from your game nights and reviews will appear here")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color("MutedText"))
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .padding(.horizontal, 16)
                            .background(Color("CardSurface").opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHStack(spacing: 12) {
                                    ForEach(profileViewModel.boardGames) { boardGame in
                                        Button {
                                            router.push(.boardGame(id: boardGame.id))
                                        } label: {
                                            AsyncImage(url: URL(string: boardGame.image ?? "")) { image in
                                                image.resizable().scaledToFill()
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.12))
                                                    .overlay(
                                                        ProgressView()
                                                    )
                                            }
                                            .frame(width: 130, height: 180)
                                            .clipped()
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                    }
                    .padding(.bottom, 32)
                    .onAppear {
                            Task {
                                await profileViewModel.getUserFriends(userID: userID, accessToken: auth.accessToken ?? "")
                                async let pendingFriends: () = profileViewModel.getUserFriendsPending(userID: auth.userID ?? 0, auth: auth)
                                await pendingFriends
                                async let boardGames: () = profileViewModel.fetchUserBoardGames(userID: userID, accessToken: auth.accessToken ?? "")
                                async let gameNights: () = profileViewModel.fetchUserGameNights(userID: userID, accessToken: auth.accessToken ?? "")
                                async let userProfile: () = profileViewModel.fetchUserProfile(userID: userID, auth: auth)
                                async let winRate: () = profileViewModel.fetchWinRate(userID: userID, accessToken: auth.accessToken ?? "")
                                await userProfile
                                await boardGames
                                await gameNights
                                await winRate
                                await withTaskGroup(of: Void.self) { group in
                                    for gameNight in profileViewModel.gameNights {
                                        let id = gameNight.id
                                        let blobNames = gameNight.images ?? []
                                        group.addTask {
                                            await profileViewModel.fetchImageURLFromBlob(id: id, blobNames: blobNames, accessToken: auth.accessToken ?? "")
                                        }
                                    }
                                }
                                isLoadingContent = false
                            }
                        }
                }
            }
            .fullScreenCover(isPresented: $addFriendsPresented) {
                FriendsSheet(profileViewModel: profileViewModel, isPresented: $addFriendsPresented, userID: userID)
            }
            .overlay {
                if isLoadingContent {
                    Color("CharcoalBackground").ignoresSafeArea()
                    ProgressView().tint(.white)
                }
            }
            .alert("Error", isPresented: Binding(
                get: { profileViewModel.errorMessage != nil },
                set: { if !$0 { profileViewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(profileViewModel.errorMessage ?? "")
            }
        }
    }

    @ViewBuilder
    private var profileAvatar: some View {
        if let profileImageURL = profileViewModel.profileImageURL {
            AsyncImage(url: URL(string: profileImageURL)) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                ProgressView()
            }
            .frame(width: 75, height: 75)
            .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 75, height: 75)
                .foregroundStyle(Color("MutedText"))
        }
    }

    @ViewBuilder
    private var gameNightImageGrid: some View {
        let nights = Array(profileViewModel.gameNights.filter { profileViewModel.imageURLs[$0.id] != nil }.prefix(4))
        switch nights.count {
        case 1:
            HStack {
                gameNightImageTile(nights[0])
                Spacer()
            }
        case 2:
            HStack(spacing: 10) {
                gameNightImageTile(nights[0])
                gameNightImageTile(nights[1])
            }
        case 3:
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    gameNightImageTile(nights[0])
                    gameNightImageTile(nights[1])
                }
                HStack {
                    gameNightImageTile(nights[2])
                        //.frame(maxWidth: .infinity)
                }
            }
        case 4:
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    gameNightImageTile(nights[0])
                    gameNightImageTile(nights[1])
                }
                HStack(spacing: 10) {
                    gameNightImageTile(nights[2])
                    gameNightImageTile(nights[3])
                }
            }
        default:
            if !isLoadingContent {
                let isNotFriend = userID != auth.userID && !profileViewModel.userFriends.contains(where: { $0.id == auth.userID ?? 0 })
                VStack(spacing: 10) {
                    Image(systemName: isNotFriend ? "lock.fill" : "dice.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(Color("MutedText"))
                    Text(isNotFriend ? "Friends only" : "No game nights yet")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(isNotFriend
                         ? "Add \(username ?? "this user") as a friend to see their game nights"
                         : (userID == auth.userID ? "Post your first game night to get started" : ""))
                        .font(.system(size: 13))
                        .foregroundStyle(Color("MutedText"))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(Color("CardSurface").opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func gameNightImageTile(_ gameNight: GameNightModel) -> some View {
        Button {
            router.push(.gameNight(id: gameNight.id))
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                if let imageURL = profileViewModel.imageURLs[gameNight.id] {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 150, height: 150)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(gameNight.description ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, minHeight: 150, maxHeight: 150, alignment: .center)
                    .padding()
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Badge

private struct ProfileStatBadge: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color("MutedText"))
        }
    }
}

// MARK: - Pending Friend Row

private struct PendingFriendRow: View {
    let friend: UserPublicModel
    let profileImageURL: String?
    let onTap: () -> Void
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button {
                onTap()
            } label: {
                HStack(spacing: 14) {
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
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    Text(friend.username)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button {
                onAccept()
            } label: {
                Text("Accept")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color("MutedText"))
            }

            Button {
                onDecline()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color("MutedText"))
            }
        }
    }
}

// MARK: - Friends Sheet

struct FriendsSheet: View {
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: Auth
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var isPresented: Bool
    let userID: Int
    @State private var selectedTab: Int = 0
    @State private var searchText: String = ""
    @State private var findSearchText: String = ""

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Friends")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                    Button {
                        isPresented.toggle()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color("PrimaryButton"))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                HStack(spacing: 0) {
                    let tabs: [(Int, String)] = userID == auth.userID
                        ? [
                            (0, "Friends"),
                            (1, profileViewModel.pendingFriends.isEmpty ? "Incoming" : "Incoming (\(profileViewModel.pendingFriends.count))"),
                            (2, "Add")
                          ]
                        : [(0, "Friends")]
                    ForEach(tabs, id: \.0) { tab, label in
                        Button {
                            selectedTab = tab
                        } label: {
                            Text(label)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(selectedTab == tab ? .white : Color("MutedText"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedTab == tab ? Color("PrimaryButton") : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(Color("CardSurface").opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                if selectedTab == 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("MutedText"))
                        TextField("", text: $searchText, prompt: Text("Search friends").foregroundStyle(Color("MutedText")))
                            .foregroundStyle(.white)
                            .tint(Color("PrimaryButton"))
                            .onChange(of: searchText) {
                                profileViewModel.filterFriends(searchText: searchText)
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(profileViewModel.filteredFriends) { friend in
                                TagFriendRow(
                                    friend: friend,
                                    profileImageURL: profileViewModel.friendProfileImages[friend.id],
                                    onTap: {
                                        router.push(.profile(id: friend.id, username: friend.username))
                                        isPresented.toggle()
                                    },
                                    onRemove: userID == auth.userID ? {
                                        Task {
                                            await profileViewModel.removeFriend(userID: auth.userID ?? 0, friendID: friend.id, auth: auth)
                                        }
                                    } : nil
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                } else if selectedTab == 1 {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(profileViewModel.pendingFriends) { friend in
                                PendingFriendRow(
                                    friend: friend,
                                    profileImageURL: profileViewModel.pendingFriendProfileImages[friend.id],
                                    onTap: {
                                        router.push(.profile(id: friend.id, username: friend.username))
                                        isPresented.toggle()
                                    },
                                    onAccept: {
                                        Task {
                                            await profileViewModel.acceptFreiendRequest(userID: auth.userID ?? 0, friendID: friend.id, auth: auth)
                                        }
                                    },
                                    onDecline: {
                                        Task {
                                            await profileViewModel.declineFriendRequest(userID: auth.userID ?? 0, friendID: friend.id, auth: auth)
                                        }
                                    }
                                )
                                .padding(14)
                                .background(Color("CardSurface").opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("MutedText"))
                        TextField("", text: $findSearchText, prompt: Text("Search by username").foregroundStyle(Color("MutedText")))
                            .foregroundStyle(.white)
                            .tint(Color("PrimaryButton"))
                            .autocapitalization(.none)
                            .onChange(of: findSearchText) {
                                Task {
                                    await profileViewModel.searchUsers(query: findSearchText, accessToken: auth.accessToken ?? "")
                                }
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)

                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(profileViewModel.userSearchResults.filter { user in
                                user.id != (auth.userID ?? 0) &&
                                !profileViewModel.userFriends.contains(where: { $0.id == user.id })
                            }) { user in
                                FindUserRow(
                                    user: user,
                                    requestSent: profileViewModel.sentFriendRequestIDs.contains(user.id),
                                    profileImageURL: profileViewModel.searchResultProfileImages[user.id]
                                ) {
                                    Task {
                                        await profileViewModel.sendFriendRequest(userID: auth.userID ?? 0, friendID: user.id, auth: auth)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { profileViewModel.errorMessage != nil },
            set: { if !$0 { profileViewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(profileViewModel.errorMessage ?? "")
        }
        .onAppear {
            Task {
                async let friends: () = profileViewModel.getUserFriends(userID: userID, accessToken: auth.accessToken ?? "")
                async let sentRequests: () = profileViewModel.loadSentFriendRequests(auth: auth)
                await friends
                await sentRequests
            }
        }
    }
}

// MARK: - Tag Friend Row

private struct TagFriendRow: View {
    let friend: UserPublicModel
    let profileImageURL: String?
    let onTap: () -> Void
    var onRemove: (() -> Void)? = nil
    @State private var showRemoveConfirm = false

    var body: some View {
        HStack(spacing: 14) {
            Button {
                onTap()
            } label: {
                HStack(spacing: 14) {
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
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                    Text(friend.username)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                    Spacer()
                    if onRemove == nil {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color("MutedText"))
                    }
                }
            }
            .buttonStyle(.plain)

            if onRemove != nil {
                Button {
                    showRemoveConfirm = true
                } label: {
                    Image(systemName: "person.badge.minus")
                        .font(.system(size: 18))
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
                .confirmationDialog("Remove \(friend.username) as a friend?", isPresented: $showRemoveConfirm, titleVisibility: .visible) {
                    Button("Remove", role: .destructive) {
                        onRemove?()
                    }
                    Button("Cancel", role: .cancel) {}
                }
            }
        }
        .padding(14)
        .background(Color("CardSurface").opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Find User Row

private struct FindUserRow: View {
    let user: UserPublicModel
    let requestSent: Bool
    let profileImageURL: String?
    let onAdd: () -> Void

    var body: some View {
        HStack(spacing: 14) {
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
            .frame(width: 46, height: 46)
            .clipShape(Circle())
            Text(user.username)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)
            Spacer()
            Button {
                onAdd()
            } label: {
                Text(requestSent ? "Sent" : "Add")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(requestSent ? Color("MutedText") : .white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(requestSent ? Color("CardSurface") : Color("PrimaryButton"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(requestSent)
        }
        .padding(14)
        .background(Color("CardSurface").opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    let auth = Auth()
    auth.setSession(AuthResponse(
        access_token: "preview-token",
        refresh_token: "preview-refresh",
        token_type: "bearer",
        user: RegisterResponse(username: "previewUser", id: 2)
    ))
    return ProfileView(userID: 2, username: "previeUser")
        .environmentObject(auth)
        .environmentObject(AppRouter())
}
