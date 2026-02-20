//
//  BookView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/12/25.
//

import SwiftUI
import SDWebImageSwiftUI
struct BoardGameView: View {
    let boardGameID: Int
    @EnvironmentObject var auth: Auth
    @State var cardImage: UIImage? = nil
    @State var boardGame: BoardGameModel? = nil
    @State var designers: [String] = []
    @StateObject private var boardGameViewModel: BoardGameViewModel

    init(boardGameID: Int) {
           self.boardGameID = boardGameID
           _boardGameViewModel = StateObject(wrappedValue: BoardGameViewModel(boardGameID: boardGameID))
       }
    
    var body: some View {
        ScrollView {
            ZStack {
                Color("BoardGameView")
                Image(uiImage: cardImage ?? UIImage())
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .clipped()
                        .padding(.top,50)
            }
            .onAppear() {
                Task {
                    await boardGameViewModel.presentBoardGame(accessToken: auth.accessToken ?? "")
                    await boardGameViewModel.presentImage()
                    boardGame = boardGameViewModel.boardGame
                    cardImage = boardGameViewModel.boardGameImage
                    await boardGameViewModel.getReviews()
                    await
                    boardGameViewModel.getUserReview(userID: auth.userID ?? 0)
                }
            }
            .frame(height: 430)
            Text(boardGame?.name ?? "Loading")
                .font(.title)
            Text(designers.joined(separator: ", "))
                .onAppear {
                    Task {
                        designers = await boardGameViewModel.getBoardGameDesigners()
                    }
                }
            HStack {
                ComputedRatingView(averageRating: boardGameViewModel.averageRating, numberOfRatings: boardGameViewModel.numberOfRatings, numberOfReviews: boardGameViewModel.numberOfReviews)
            }
            .onAppear {
                Task {
                    await boardGameViewModel.getReviewStats(boardGameID: boardGameID)
                }
            }
            .padding(.top,10)
            Rectangle()
                .fill(Color.gray)
                .opacity(0.50)
                .frame(height: 2)
            WantToPlayButtonView()
                .padding(.bottom,10)
            RateThisGameFullView(id: boardGameID, rating:  $boardGameViewModel.userRating)
            //ReviewButton()
                //.padding(.bottom,10)
            Rectangle()
                .fill(Color.gray)
                .opacity(0.50)
                .frame(height: 2)
                .padding(.top,30)
            HStack {
                Spacer()
                VStack {
                    Image(systemName: "info.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.gray)
                    Text("More Info")
                }
                Spacer()
                Rectangle()
                    .fill(Color.gray)
                    .opacity(0.50)
                    .frame(width: 1)
                Spacer()
                VStack {
                    Image(systemName: "arrowshape.turn.up.forward.circle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color.gray)
                    Text("Share")
                }
                Spacer()
            }
            Rectangle()
                .fill(Color.gray)
                .opacity(0.50)
                .frame(height: 1)
                .padding(.top,10)
            
            LazyVStack {
                ForEach(boardGameViewModel.reviews) { review in
                    ReviewCardView(reviewModel: review)
                }
                
            }
                
        }
        .edgesIgnoringSafeArea(.top)
    }
}

#Preview {
    BoardGameView(boardGameID:181)
        .environmentObject(Auth())
}
