//
//  AppRouter.swift
//  boardGameReview
//
//  Created by Robert Fusting on 3/6/26.
//
import SwiftUI

final class AppRouter: ObservableObject {
    @Published var path = NavigationPath()
    @Published var gameNightPosted: Bool = false
    @Published var reviewPosted: Bool = false

    func push(_ route: AppRoute) { path.append(route) }
    func pop() { if !path.isEmpty { path.removeLast() } }
    func popToRoot() { path = NavigationPath() }
}
