//
//  BoardGameModel.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/6/25.
//

import Foundation
import UIKit

struct BoardGameModel: Identifiable, Codable, Hashable {
    let id : Int
    let name : String
    let thumbnail : String?
    let play_time : Int?
    let min_players : Int?
    let max_players : Int?
    let year_published : Int?
    let description : String?
    let min_age : Int?
    let image : String?
}

struct BoardGameFeedModel: Identifiable, Codable {
    let id : Int
    let name : String
    let thumbnail : String?
    let play_time : Int?
    let min_players : Int?
    let max_players : Int?
    let year_published : Int?
    let description : String?
    let min_age : Int?
    let image : String?
    let average_rating: Double?
    let number_of_reviews: Int
    let number_of_ratings: Int
    let designers: [String]?
}


