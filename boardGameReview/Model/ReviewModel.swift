//
//  ReviewModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/6/25.
//

import Foundation

struct ReviewUpdate: Codable {
    let id: Int
    var rating: Int?
    var comment: String?
}

struct ReviewModel: Identifiable, Codable, Hashable {
    let id: Int?
    let board_game_id: Int
    let user_id: Int
    let username: String
    var rating: Int
    var comment: String?
    var date_created: String?
}

struct ReviewPublicModel: Identifiable, Codable {
    let id: Int
    let board_game_id: Int
    let user: UserProfileModel
    let rating: Int
    let comment: String?
    let date_created: String?
    let likes_count: Int
    let user_has_liked: Bool
}
