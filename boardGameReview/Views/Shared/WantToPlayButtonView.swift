//
//  WantToPlayButtonView.swift
//  boardGameReview
//
//  Created by Robert Fusting on 12/7/25.
//

import SwiftUI

struct WantToPlayButtonView: View {
    var body: some View {
            HStack(spacing: 0) {
                Text("See More")
                    .foregroundStyle(Color.white)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 16)
                    .font(.system(size:15))
                Divider()
                    .frame(width: 2, height: 28)
                    .background(Color.white.opacity(0.25))
                Image(systemName: "arrowtriangle.down.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 8)
            }
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color("WantToPlayButton"))
            )
            .frame(height: 40)
    }
}

#Preview {
    WantToPlayButtonView()
}
