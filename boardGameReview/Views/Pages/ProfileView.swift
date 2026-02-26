//
//  ProfileView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/13/25.
//

import SwiftUI

struct ProfileView: View {
    let userID: Int
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Text("Robert Fusting")
                    .padding(.trailing, 60)
                    .padding(.bottom, -5)
                    .padding(.top)
                Spacer()
            }
            HStack(alignment: .center, spacing: 20) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 75, height: 75)
                    .foregroundStyle(Color("MutedText"))
                    .padding(.trailing, 20)
                VStack(spacing:3) {
                    Text("0")
                    Text("Posts")
                }
                VStack(spacing:3) {
                    Text("140")
                    Text("Friends")
                }
                VStack(spacing:3) {
                    Text("50")
                    Text("Games Played")
                }
                
            }
            .padding(.horizontal)
        }
        VStack(alignment: .leading) {
            Text("Game nights")
                .padding()
                .padding(.bottom, -10)
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: 1)
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(0..<4) { index in
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: .infinity, height: 150)
                    }
                }
                .padding()
                Button {} label : {
                    Text("See All")
                        .padding()
                        .frame( maxWidth: .infinity, alignment: .trailing)
                }
            
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: 1)
            
            HStack {
                Text("Games")
                Spacer()
                Text("Avg Win rate: 70%")
            }
            .padding()
            
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    ForEach(0..<10) { index in
                        Rectangle()
                            .fill(Color.gray.opacity(0.4))
                            .frame(width: 100, height: 150)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView(userID: 0)
}
