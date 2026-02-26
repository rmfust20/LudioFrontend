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
    var body: some Scene {
        WindowGroup {
            ImageSelection()
                .environmentObject(auth)
                .environmentObject(userViewModel)
        }
    }
}
