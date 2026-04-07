//
//  SearchView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI
import UIKit

struct SearchView: View {
    @EnvironmentObject var auth: Auth
    @Binding var isPresented: Bool
    @Binding var selectedBoardGameID : Int?
    @State private var searchText: String = ""
    @State private var searchViewModel = SearchViewModel()
    var body: some View {
        if isPresented {
            ZStack {
                Color("CharcoalBackground").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button {
                            isPresented = false
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color("MutedText"))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 8)

                    // Search bar
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color("MutedText"))

                        TextField("", text: $searchText, prompt: Text("Board Game Name").foregroundStyle(Color("MutedText")))
                            .foregroundStyle(.white)
                            .onChange(of: searchText) {
                                searchViewModel.performSearch(searchText: searchText, accessToken: auth.accessToken ?? "")
                            }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color("CardSurface"))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            if searchViewModel.isLoading {
                                ProgressView()
                                    .tint(Color("MutedText"))
                                    .padding(.top, 40)
                            } else if !searchText.isEmpty && searchViewModel.searchResults.isEmpty {
                                Text("No results found")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color("MutedText"))
                                    .padding(.top, 40)
                            } else {
                                ForEach(searchViewModel.searchResults) { boardgame in
                                    SearchPreviewView(
                                        name: boardgame.name,
                                        image: searchViewModel.images[boardgame.id],
                                        onSelect: {
                                            selectedBoardGameID = boardgame.id
                                        }
                                    )
                                    .onAppear {
                                        searchViewModel.loadImage(for: boardgame)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

struct SearchPreviewView : View {
    let name : String
    let image : UIImage?
    let onSelect : () -> Void
    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Group {
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.12))
                                .overlay(
                                    Image(systemName: "photo")
                                        .font(.system(size: 20))
                                        .foregroundStyle(Color.gray.opacity(0.3))
                                )
                        }
                    }
                    .frame(width: 64, height: 82)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    Text(name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color("MutedText"))
                }
                .padding(14)

                Rectangle().fill(Color.gray.opacity(0.12))
                    .frame(height: 1)
                    .padding(.horizontal, 14)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)

    }
}

#Preview {
    SearchView(isPresented: .constant(true), selectedBoardGameID: .constant(0))
}
