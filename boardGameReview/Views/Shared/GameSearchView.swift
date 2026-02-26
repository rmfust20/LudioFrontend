//
//  GameSearchView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/24/26.
//

import SwiftUI

struct GameSearchView: View {
    @State var text: String = ""
    var body: some View {
        TextField("Search for a game", text: $text)
    }
}

#Preview {
    GameSearchView()
}
