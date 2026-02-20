//
//  SearchView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI

struct SearchView: View {
    @State private var searchText: String = ""
    var body: some View {
        ZStack {
            Color("WantToPlayButton")
                .opacity(0.75)
                .ignoresSafeArea()
            HStack {
                Image(systemName: "magnifyingglass")
                    .opacity(0.5)
                    .padding(.leading, 8)
                    .padding(.vertical, 6)
                TextField("Board Game Name", text: $searchText)
            }
            .background(
                Capsule()
                    .fill(Color.white)
                )
            .padding()
        }
        .frame(maxHeight:100)
    }
}

#Preview {
    SearchView()
}
