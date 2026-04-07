//
//  ProfileViewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/13/26.
//

import Foundation
import PhotosUI
import _PhotosUI_SwiftUI

class ProfileViewModel: ObservableObject {
    private let boardGameService: BoardGameService
    private let gameNightService: GameNightService
    private let imageService: ImageService
    private let userService: UserService

    @Published var boardGames: [BoardGameModel] = []
    @Published var gameNights: [GameNightModel] = []
    @Published var imageURLs: [Int: String] = [:]
    @Published var profileImageURL: String?
    @Published var selectedItem: [PhotosPickerItem] = []
    @Published var isUploading = false
    @Published var uploaded: [UploadImagesResponse.UploadedFile] = []
    @Published var errorMessage: String?
    @Published var userFriends: [UserPublicModel] = []
    @Published var filteredFriends: [UserPublicModel] = []
    @Published var pendingFriends: [UserPublicModel] = []
    @Published var userSearchResults: [UserPublicModel] = []
    @Published var sentFriendRequestIDs: Set<Int> = []
    @Published var winRate: Double? = nil
    @Published var friendProfileImages: [Int: String] = [:]
    @Published var pendingFriendProfileImages: [Int: String] = [:]
    @Published var searchResultProfileImages: [Int: String] = [:]

    init(boardGameService: BoardGameService = BoardGameService(), gameNightService: GameNightService = GameNightService(), imageService: ImageService = ImageService(), userService: UserService = UserService()) {
        self.boardGameService = boardGameService
        self.gameNightService = gameNightService
        self.imageService = imageService
        self.userService = userService
    }
    
    @MainActor
    func fetchUserBoardGames(userID: Int, accessToken: String) async {
        let games = try? await gameNightService.getUserBoardGames(userID: userID, accessToken: accessToken)

        if let games {
            self.boardGames = games
        }
    }

    @MainActor
    func fetchUserGameNights(userID: Int, accessToken: String) async {
        let nights = try? await gameNightService.getUserGameNights(userID: userID, accessToken: accessToken)

        if let nights {
            self.gameNights = nights
        }
    }

    @MainActor
    func fetchImageURLFromBlob(id: Int, blobNames: [String?], accessToken: String) async {
        var blobFinal: [String] = []
        for blobName in blobNames {
            if let blobName = blobName {
                blobFinal.append(blobName)
            }
        }
        let urls = try? await imageService.getImageURLs(blobNames: blobFinal, accessToken: accessToken)
        if let firstURL = urls?.first {
            self.imageURLs[id] = firstURL
        }
    }
    
    @MainActor
    func handleImageChange(auth: Auth) async {
        guard !selectedItem.isEmpty else { return }
        errorMessage = nil
        uploaded = []
        isUploading = true
        defer { isUploading = false }

        do {
            print("[ProfileImageUpload] starting upload")
            uploaded = try await imageService.uploadSelectedImages(selectedImages: selectedItem, accessToken: auth.accessToken ?? "")

            let blobNames = uploaded.compactMap { $0.blob_name }
            print("[ProfileImageUpload] uploaded blob names: \(blobNames)")

            let url = blobNames.first

            if let url = url {
                print("[ProfileImageUpload] updating user profile with blob: \(url)")
                let updatedUser = UserProfileModel(
                    id: auth.userID ?? 0,
                    username: nil,
                    email: nil,
                    profile_image_url: url
                )
                let blob_name = try await userService.updateUser(updatedUser: updatedUser, accessToken: auth.accessToken ?? "").profile_image_url
                print("[ProfileImageUpload] updateUser returned blob_name: \(String(describing: blob_name))")

                if let blob_name = blob_name {
                    profileImageURL = try await imageService.getImageURL(blobName: blob_name, accessToken: auth.accessToken ?? "")
                    print("[ProfileImageUpload] resolved image URL: \(String(describing: profileImageURL))")
                }
            }
        } catch {
            print("[ProfileImageUpload] failed: \(error)")
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    func fetchUserProfile(userID: Int, auth: Auth) async {
        let user = try? await userService.getUser(userID: userID, accessToken: auth.accessToken ?? "")
        if let user = user {
            if let image_url = user.profile_image_url {
                profileImageURL = try? await imageService.getImageURL(blobName: image_url, accessToken: auth.accessToken ?? "")
            }
        }
    }

    @MainActor
    func getUserFriends(userID: Int, accessToken: String) async {
        let friends = try? await gameNightService.getUserFriends(userID: userID, accessToken: accessToken)
        if let friends = friends {
            self.userFriends = friends
            self.filteredFriends = friends
            friendProfileImages = await fetchProfileImages(for: friends.map { $0.id }, accessToken: accessToken)
        }
    }
    
    @MainActor
    func filterFriends(searchText: String) {
        filteredFriends = userFriends.filter { friend in
            friend.username.lowercased().starts(with: searchText.lowercased())
            
        }
        filteredFriends.sort { $0.username.lowercased() < $1.username.lowercased() }
    }
    
    @MainActor
    func sendFriendRequest(userID: Int, friendID: Int, auth: Auth) async {
        do {
            try await userService.sendFriendRequest(userID: userID, friendID: friendID, accessToken: auth.accessToken ?? "")
            sentFriendRequestIDs.insert(friendID)
        } catch {
            errorMessage = "Failed to send friend request."
        }
    }
    
    @MainActor
    func getUserFriendsPending(userID: Int, auth: Auth) async {
        do {
            let pendingRequests = try await userService.getUserFriendsPending(userID: userID, accessToken: auth.accessToken ?? "")
            pendingFriends = pendingRequests
            pendingFriendProfileImages = await fetchProfileImages(for: pendingRequests.map { $0.id }, accessToken: auth.accessToken ?? "")
        } catch {
            print("Error fetching pending friend requests: \(error)")
        }
    }
    
    @MainActor
    func declineFriendRequest(userID: Int, friendID: Int, auth: Auth) async {
        do {
            try await userService.rejectFriend(userID: userID, friendID: friendID, accessToken: auth.accessToken ?? "")
            pendingFriends.removeAll { $0.id == friendID }
        } catch {
            errorMessage = "Failed to decline friend request."
        }
    }

    @MainActor
    func acceptFreiendRequest(userID: Int, friendID: Int, auth: Auth) async {
        do {
            try await userService.acceptFriend(userID: userID, friendID: friendID, accessToken: auth.accessToken ?? "")
            pendingFriends.removeAll { $0.id == friendID }
        } catch {
            errorMessage = "Failed to accept friend request."
        }
    }

    @MainActor
    func logout(auth: Auth) async {
        try? await userService.logout(refreshToken: auth.refreshToken ?? "", accessToken: auth.accessToken ?? "")
        auth.clear()
    }

    @MainActor
    func deleteAccount(auth: Auth) async {
        try? await userService.deleteAccount(accessToken: auth.accessToken ?? "")
        auth.clear()
    }

    @MainActor
    func loadSentFriendRequests(auth: Auth) async {
        let sent = try? await userService.getSentFriendRequests(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
        sentFriendRequestIDs = Set((sent ?? []).map { $0.id })
    }

    @MainActor
    func fetchWinRate(userID: Int, accessToken: String) async {
        let result = try? await userService.getWinRate(userID: userID, accessToken: accessToken)
        winRate = result?.win_rate
    }

    @MainActor
    func searchUsers(query: String, accessToken: String) async {
        guard !query.isEmpty else {
            userSearchResults = []
            searchResultProfileImages = [:]
            return
        }
        let results = try? await userService.searchUsers(username: query, accessToken: accessToken)
        userSearchResults = results ?? []
        searchResultProfileImages = await fetchProfileImages(for: userSearchResults.map { $0.id }, accessToken: accessToken)
    }

    private func fetchProfileImages(for userIDs: [Int], accessToken: String) async -> [Int: String] {
        let profiles = (try? await userService.getUsers(userIDs: userIDs, accessToken: accessToken)) ?? []
        let blobEntries: [(Int, String)] = profiles.compactMap { p in
            guard let blob = p.profile_image_url else { return nil }
            return (p.id, blob)
        }
        guard !blobEntries.isEmpty else { return [:] }
        let urls = (try? await imageService.getImageURLs(blobNames: blobEntries.map { $0.1 }, accessToken: accessToken)) ?? []
        var result: [Int: String] = [:]
        for (index, (userID, _)) in blobEntries.enumerated() where index < urls.count {
            result[userID] = urls[index]
        }
        return result
    }
}
