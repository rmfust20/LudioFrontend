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

    init(boardGameService: BoardGameService = BoardGameService(), gameNightService: GameNightService = GameNightService(), imageService: ImageService = ImageService(), userService: UserService = UserService()) {
        self.boardGameService = boardGameService
        self.gameNightService = gameNightService
        self.imageService = imageService
        self.userService = userService
    }
    
    @MainActor
    func fetchUserBoardGames(userID: Int) async {
        let games = try? await gameNightService.getUserBoardGames(userID: userID)
        
        if let games {
            self.boardGames = games
        }
    }
    
    @MainActor
    func fetchUserGameNights(userID: Int) async {
        let nights = try? await gameNightService.getUserGameNights(userID: userID)

        if let nights {
            self.gameNights = nights
        }
    }

    @MainActor
    func fetchImageURLFromBlob(id: Int, blobNames: [String?]) async {
        var blobFinal: [String] = []
        for blobName in blobNames {
            if let blobName = blobName {
                blobFinal.append(blobName)
            }
        }
        let urls = try? await imageService.getImageURLs(blobNames: blobFinal)
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
            uploaded = try await imageService.uploadSelectedImages(selectedImages: selectedItem, accessToken: auth.accessToken ?? "")

            
            let blobNames = uploaded.compactMap { $0.blob_name }
            
            let url = blobNames.first

            
            if let url = url {
                print("url is \(url)")
                let updatedUser = UserProfileModel(
                    id: auth.userID ?? 0,
                    username: nil,
                    email: nil,
                    profile_image_url: url
                )
                let blob_name = try await userService.updateUser(updatedUser: updatedUser, accessToken: auth.accessToken ?? "").profile_image_url
                
                if let blob_name = blob_name {
                    profileImageURL = try await imageService.getImageURL(blobName: blob_name)
                }
                
                
            }
            
        }
        
        catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    func fetchUserProfile(auth: Auth) async {
        let user = try? await userService.getUser(userID: auth.userID ?? 0)
        
        print ("user is \(user)")
        
        if let user = user {
            if let image_url = user.profile_image_url {
                profileImageURL = try? await imageService.getImageURL(blobName: image_url)
            }
        }
    }
    
    @MainActor
    func getUserFriends(userID: Int) async {
        let friends = try? await gameNightService.getUserFriends(userID: userID)
        if let friends = friends {
            self.userFriends = friends
            self.filteredFriends = friends
        }
    }
    
    @MainActor
    func filterFriends(searchText: String) {
        filteredFriends = userFriends.filter { friend in
            friend.username.lowercased().starts(with: searchText.lowercased())
            
        }
        filteredFriends.sort { $0.username.lowercased() < $1.username.lowercased() }
    }
    
    func sendFriendRequest(userID: Int, friendID: Int, auth: Auth) async {
        do {
            try? await userService.sendFriendRequest(userID: userID, friendID: friendID, accessToken: auth.accessToken ?? "")
        }
    }
    
    @MainActor
    func getUserFriendsPending(userID: Int, auth: Auth) async {
        do {
            let pendingRequests = try await userService.getUserFriendsPending(userID: userID, accessToken: auth.accessToken ?? "")
            pendingFriends =  pendingRequests
        } catch {
            print("Error fetching pending friend requests: \(error)")
        }
    }
    
    @MainActor
    func declineFriendRequest(userID: Int, friendID: Int, auth: Auth) async {
        do {
            try? await userService.rejectFriend(userID: userID, friendID: friendID, accessToken: auth.accessToken ?? "")
        }
        
        pendingFriends.removeAll { $0.id == friendID }
    }
}
