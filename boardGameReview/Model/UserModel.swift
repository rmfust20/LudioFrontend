//
//  UserModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/6/25.
//

import Foundation

struct UserModel: Identifiable, Codable {
    let id: Int?
    let username: String
    let email: String
    var password: String
    var profile_image_url: String?
}

struct UserUpdateModel: Identifiable, Codable {
    let id: Int
    let username: String?
    let email: String?
    var profile_image_url: String?
}

struct UserPublicModel: Identifiable, Codable {
    let id: Int
    let username: String
}

struct UserProfileModel: Identifiable, Codable {
    let id: Int
    let username: String?
    let profile_image_url: String?
}

