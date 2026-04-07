//
//  GameNightModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/8/26.
//

import Foundation

struct GameNightUploadModel: Codable {
    let host_user_id: Int
    let description: String?
    let images: [String]? // Assuming images are represented as URLs or base64 strings
    let sessions: [GameNightSessionUploadModel]
    let users: [Int]?
}

struct GameNightSessionUploadModel: Codable {
    let board_game_id: Int
    let duration_minutes: Int?
    let winner_user_ids: [Int]
}

struct GameNightSessionModel: Codable {
    let board_game: BoardGameModel
    let duration_minutes: Int?
    let winners_user_id: [Int?]
}



struct UsersGameNightsModel: Codable {
    let id: Int
    let username: String
}

struct GameNightModel : Codable, Identifiable {
    let id : Int
    let host_user_id : Int
    let game_night_date : String
    let description : String?
    let sessions : [GameNightSessionModel]
    let images : [String]?
    let users : [UserProfileModel]
}

struct PlayerFeedModel: Identifiable {
    let id: Int
    let username: String
    let profileImageURL: String?
    let isWinner: Bool
}

struct GameNightFeedModel: Identifiable {
    let id: Int
    let hostUserID: Int
    let hostUsername: String
    let hostProfileImageURL: String?
    let date: String
    let description: String?
    let photos: [String]
    let players: [PlayerFeedModel]
    let sessions: [GameNightSessionModel]
}
