//
//  HomeView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var router: HomeRouter
    @EnvironmentObject private var auth: Auth
    @StateObject var homeFeedViewModel = HomeFeedViewModel()
    @ObservedObject var reviewViewModel = ReviewViewModel()
    @State private var showStars: Bool = false
    let userID = 1
    var body: some View {
        SearchView()
            .padding(.vertical,-10)
        ZStack {
            Color("SoftOffWhite")
            ScrollView {
                LazyVStack {
                    ForEach(homeFeedViewModel.boardGames) { boardGame in
                        Button {router.push(.boardGame(id: boardGame.id))} label: {
                            BoardGameCardView(boardGame: boardGame, showStars: $showStars, cardImage: ImageCache.shared.getImage(for: boardGame.id))
                        }
                        .buttonStyle(.plain)
                            .onAppear() {
                                Task {
                                    await homeFeedViewModel.updateImageCache(boardGame: boardGame)
                                }
                                if boardGame.id == homeFeedViewModel.boardGames.last?.id {
                                    Task { await homeFeedViewModel.fetchBoardGamesFromNetwork(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                                    }
                                }
                            }
                    }
                }
            }
            .onAppear() {
                Task {
                    await homeFeedViewModel.fetchBoardGames(userID: auth.userID ?? 0, accessToken: auth.accessToken ?? "")
                }
            }
            AddStars(isPresented: $showStars)
            
        }
    }
}

struct AddStars: View {
    let bookTitle: String = "Sample Book"
    @Binding var isPresented: Bool
    var body: some View {
        if isPresented {
            VStack {
                Spacer()
                List {
                    HStack{
                        Spacer()
                        Text(bookTitle)
                            .font(.system(size:12))
                            .foregroundStyle(Color.gray)
                        Spacer()
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                        dimensions[.leading]
                    }
                    ForEach(1...5, id: \.self) { index in
                        HStack {
                            Spacer()
                            ForEach(1...index, id:\.self) { star_count in
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.gray)
                                    .padding(.trailing,-10)
                            }
                            Text("\(index) Stars" )
                                .padding(.leading,5)
                            Spacer()
                        }
                        .alignmentGuide(.listRowSeparatorLeading) { dimensions in
                            dimensions[.leading]
                        }
                    }
                    HStack{
                        Spacer()
                        Button {
                            withAnimation(.spring(response:0.50)) {
                                isPresented = false
                            }
                        } label : {
                            Text("Cancel")
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height / 2)
                
            }
            .transition(.move(edge: .bottom))
        }
    }
}


#Preview {
  HomeView().environmentObject(HomeRouter())
}
