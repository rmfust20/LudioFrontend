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
    @State private var pendingFriendsPresented: Bool = false
    let userID: Int

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack(alignment: .center) {
                        Text(auth.username ?? "Loading...")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(.white)
                        Spacer()
                        if userID != auth.userID {
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
                        } else {
                            HStack(spacing: 12) {
                                Button {
                                    pendingFriendsPresented.toggle()
                                } label: {
                                    Image(systemName: "person.crop.circle")
                                        .font(.system(size: 22))
                                        .foregroundStyle(.white)
                                        .overlay(alignment: .topTrailing) {
                                            if profileViewModel.pendingFriends.count > 0 {
                                                Text("\(profileViewModel.pendingFriends.count)")
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundStyle(.white)
                                                    .padding(4)
                                                    .background(Color.red)
                                                    .clipShape(Circle())
                                                    .offset(x: 6, y: -6)
                                            }
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    // Profile card
                    HStack(alignment: .center, spacing: 24) {
                        PhotosPicker(
                            selection: $profileViewModel.selectedItem,
                            maxSelectionCount: 1,
                            matching: .images
                        ) {
                            if profileViewModel.profileImageURL != nil {
                                AsyncImage(url: URL(string: profileViewModel.profileImageURL!)) { image in
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
                        .buttonStyle(.plain)
                        .onChange(of: profileViewModel.selectedItem) { oldValue, newValue in
                            Task {
                                await profileViewModel.handleImageChange(auth: auth)
                            }
                        }

                        Spacer()

                        ProfileStatBadge(value: String(profileViewModel.gameNights.count), label: "Posts")

                        Button {
                            addFriendsPresented.toggle()
                        } label: {
                            ProfileStatBadge(value: String(profileViewModel.userFriends.count), label: "Friends")
                        }
                        .buttonStyle(.plain)

                        ProfileStatBadge(value: "50", label: "Games")
                    }
                    .padding(20)
                    .background(Color("CardSurface"))
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
                            Button {
                                router.push(.gameNightFeed(userOnly: true))
                            } label: {
                                Text("See All")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color("PrimaryButton"))
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
                            Text("Avg Win Rate: 70%")
                                .font(.system(size: 13))
                                .foregroundStyle(Color("MutedText"))
                        }
                        .padding(.horizontal, 20)

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
                        .onAppear {
                            Task {
                                await profileViewModel.getUserFriends(userID: 1)
                                async let pendingFriends: () = profileViewModel.getUserFriendsPending(userID: auth.userID ?? 0, auth: auth)
                                await pendingFriends
                                async let boardGames: () = profileViewModel.fetchUserBoardGames(userID: userID)
                                async let gameNights: () = profileViewModel.fetchUserGameNights(userID: userID)
                                async let userProfile: () = profileViewModel.fetchUserProfile(auth: auth)
                                await userProfile
                                await boardGames
                                await gameNights
                                await withTaskGroup(of: Void.self) { group in
                                    for gameNight in profileViewModel.gameNights {
                                        let id = gameNight.id
                                        let blobNames = gameNight.images ?? []
                                        group.addTask {
                                            await profileViewModel.fetchImageURLFromBlob(id: id, blobNames: blobNames)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 32)
                }
            }
            .fullScreenCover(isPresented: $addFriendsPresented) {
                TagFriendsProfile(profileViewModel: profileViewModel, isPresented: $addFriendsPresented)
            }
            .fullScreenCover(isPresented: $pendingFriendsPresented) {
                PendingFriendsProfile(profileViewModel: profileViewModel, isPresented: $pendingFriendsPresented)
            }
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
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    gameNightImageTile(nights[0])
                    gameNightImageTile(nights[1])
                }
                HStack {
                    Spacer()
                    gameNightImageTile(nights[2])
                        .frame(maxWidth: .infinity)
                    Spacer()
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
            EmptyView()
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
                    .background(Color("CardSurface"))
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

// MARK: - Pending Friends Sheet

struct PendingFriendsProfile: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject private var auth: Auth

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Friend Requests")
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

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(profileViewModel.pendingFriends) { friend in
                            Button {
                                router.push(.profile(id: friend.id))
                            } label: {
                                    HStack(spacing: 14) {
                                        Image(systemName: "person.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 46, height: 46)
                                            .foregroundStyle(Color("MutedText"))
                                        Text(friend.username)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Spacer()
                                        Button{
                                            print("hello mello bello")
                                        } label: {
                                            Text("Accept")
                                                .font(.system(size: 15, weight: .semibold))
                                                .foregroundStyle(Color("MutedText"))
                                        }
                                    }
                                    .padding(14)
                                    .background(Color("CardSurface"))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                Button {
                                    Task {
                                        await profileViewModel.declineFriendRequest(userID: auth.userID ?? 0, friendID: friend.id, auth: auth)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(Color("MutedText"))
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
}

// MARK: - Tag Friends Sheet

struct TagFriendsProfile: View {
    @EnvironmentObject private var router: AppRouter
    @ObservedObject var profileViewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @State var searchText: String = ""
    @State var taggedFriends: [String] = []

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

                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("MutedText"))
                    TextField("Search friends", text: $searchText)
                        .foregroundStyle(.white)
                        .tint(Color("PrimaryButton"))
                        .onChange(of: searchText) {
                            profileViewModel.filterFriends(searchText: searchText)
                        }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color("CardSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(profileViewModel.filteredFriends) { friend in
                            Button {
                                router.push(.profile(id: friend.id))
                            } label: {
                                HStack(spacing: 14) {
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 46, height: 46)
                                        .foregroundStyle(Color("MutedText"))
                                    Text(friend.username)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Color("MutedText"))
                                }
                                .padding(14)
                                .background(Color("CardSurface"))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .onAppear {
            Task {
                await profileViewModel.getUserFriends(userID: 1)
            }
        }
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
    return ProfileView(userID: 2)
        .environmentObject(auth)
        .environmentObject(AppRouter())
}
