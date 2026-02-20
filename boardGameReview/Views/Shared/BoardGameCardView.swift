//
//  BoardGameCardView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI
import SDWebImageSwiftUI

struct BoardGameCardView: View {
    //@EnvironmentObject private var router: HomeRouter
    let boardGame: BoardGameModel
    @Binding var showStars : Bool
    let cardImage: UIImage?
    var body: some View {
        ZStack {
            HStack {
                Image(uiImage: cardImage ?? UIImage())
                    .resizable()
                    .frame(width:100, height:140)
                    .scaledToFit()
                VStack(alignment: .leading, spacing: 14) {
                    Text(boardGame.name)
                        .font(.system(size:25))
                        .buttonStyle(.plain)
                    WantToPlayButtonView()
                    RateThisGameView(isPresented: $showStars)
                }
            }
            
            .padding()
            .padding(.bottom,30)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 1)
                    .opacity(0.5)
            )
            .background(Color.white)
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    BoardGameCardView(boardGame: BoardGameModel(
        id: 1,
        name: "Die Macher",
        thumbnail: "https://cf.geekdo-images.com/rpwCZAjYLD940NWwP3SRoA__small/img/YT6svCVsWqLrDitcMEtyazVktbQ=/fit-in/200x150/filters:strip_icc()/pic4718279.jpg",
        play_time: 60,
        min_players: 3,
        max_players: 4,
        year_published: 1995,
        description: "Trade, build, and settle the island of Catan.",
        min_age: 10,
        image: "https://example.com/catan-image.jpg"
    ),showStars: .constant(false), cardImage: nil)
}
