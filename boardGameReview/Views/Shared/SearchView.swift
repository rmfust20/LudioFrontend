//
//  SearchView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI

struct SearchView: View {
    @Binding var isPresented: Bool
    @Binding var selectedBoardGameID : Int?
    @State private var searchText: String = ""
    @State private var searchViewModel = SearchViewModel()
    var body: some View {
        if isPresented {
            VStack {
                ZStack {
                    Color("WantToPlayButton")
                        .opacity(0.75)
                        .ignoresSafeArea()
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .opacity(0.5)
                            .padding(.leading, 8)
                            .padding(.vertical, 6)
                        Button {} label: {
                            TextField("Board Game Name", text: $searchText)
                                .multilineTextAlignment(.leading)
                        }.onChange(of: searchText) {
                            Task {
                                await searchViewModel.performSearch(searchText: searchText)
                            }
                        }
                    }
                    .background(
                        Capsule()
                            .fill(Color.white)
                    )
                    .padding()
                }
                .frame(maxHeight:100)
                ScrollView {
                    ForEach(searchViewModel.searchResults) {
                        boardgame in
                        SearchPreviewView(
                            name: boardgame.name,
                            image: ImageCache.shared.getImage(for: boardgame.id),
                            onSelect: {
                                selectedBoardGameID = boardgame.id
                            }
                        )
                        .padding()
                        .onAppear {
                            Task {
                                await searchViewModel.updateImageCache(boardGame: boardgame)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct SearchPreviewView : View {
    let name : String
    @State var image : UIImage? = nil
    let onSelect : () -> Void
    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipped()
                    Text(name)
                        .padding(.horizontal, 20)
                    Spacer()
                }
            }
        }.buttonStyle(.plain)
        if image != nil {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: 1)
        }
    }
}

#Preview {
    SearchView(isPresented: .constant(true), selectedBoardGameID: .constant(0))
}
