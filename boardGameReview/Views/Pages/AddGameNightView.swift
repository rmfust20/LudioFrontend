import SwiftUI

struct AddGameNightView: View {
    @State private var games: [BoardGameModel] = []
    @State private var isPresented: Bool = false
    @State var selectedBoardGameID : Int? = nil
    @StateObject private var gameNightViewModel = GameNightViewModel()

    var body: some View {
            VStack {
                Text("Share")
                
                Button {
                    isPresented.toggle()
                } label: {
                    HStack { Text("Add Game") }
                }
                SearchView(isPresented: $isPresented, selectedBoardGameID: $selectedBoardGameID)
                    .onChange(of: selectedBoardGameID) {
                        Task {
                            let game = await gameNightViewModel.fetchBoardGame(selectedBoardGameID ?? -1)
                            if let game {
                                games.append(game)
                            }
                        }
                    }
                ScrollView {
                    ForEach(games, id: \.id) { game in
                        AddGameView(boardGame: game, image: ImageCache.shared.getImage(for: game.id))
                            .onAppear() {
                                Task {
                                    await gameNightViewModel.updateImageCache(boardGame: game)
                                }
                            }
                    }
                }
                ImageSelection()
        }
            .fullScreenCover(isPresented: $isPresented) {
                SearchView(isPresented: $isPresented, selectedBoardGameID: $selectedBoardGameID)
            }
    }
}

struct AddGameView: View {
    let boardGame: BoardGameModel
    @State var image: UIImage?
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: 1)

            HStack {
                Image(uiImage: image ?? UIImage())
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)

                VStack(spacing: 60) {
                    Text("Winners: ")
                    Text("Playtime: ")
                }

                VStack(spacing: 45) {
                    Button { } label: { Text("Add Winner(s)") }
                    Button { } label: { Text("Add Duration") }
                }
                .padding()
            }

            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(maxWidth: .infinity, maxHeight: 1)
        }
    }
}

#Preview {
    AddGameNightView()
}
