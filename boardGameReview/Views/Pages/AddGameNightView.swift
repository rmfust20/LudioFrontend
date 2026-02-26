import SwiftUI

struct AddGameNightView: View {
    @State private var games: [BoardGameModel] = []
    @State private var isPresented: Bool = false
    @State var selectedBoardGameID : Int? = nil
    @StateObject private var gameNightViewModel = GameNightViewModel()
    @State private var text : String = ""
    @State private var placeholderText: String = "What happened?"

    var body: some View {
            ScrollView {
                VStack(alignment: .leading) {
                    Button {
                        isPresented.toggle()
                    } label: {
                        Text("Add Game")
                            .padding()
                            
                    }
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: 1)
                    ForEach(games, id: \.id) { game in
                        AddGameView(boardGame: game, image: ImageCache.shared.getImage(for: game.id))
                            .onAppear() {
                                Task {
                                    await gameNightViewModel.updateImageCache(boardGame: game)
                                }
                            }
                    }
                    ZStack (alignment:.topLeading){
                        TextEditor(text: $text)
                            .frame(height: 200)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5))
                            )
                            .padding()
                        if text.isEmpty {
                            Text("What happened?")
                                .foregroundColor(.gray)
                                .opacity(0.7)
                                .padding(.top,40)
                                .padding(.leading,32)
                        }
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: 1)
                    
                    Button {} label:{
                        Text("Tag Friends")
                            .padding()
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: 1)
                    
                    ImageSelection()
                        .padding()
                }
                .fullScreenCover(isPresented: $isPresented) {
                    SearchView(isPresented: $isPresented, selectedBoardGameID: $selectedBoardGameID)
                        .onChange(of: selectedBoardGameID) {
                            Task {
                                let game = await gameNightViewModel.fetchBoardGame(selectedBoardGameID ?? -1)
                                if let game {
                                    games.append(game)
                                }
                                isPresented.toggle()
                            }
                    }
            }
        }
    }
}

struct AddGameView: View {
    let boardGame: BoardGameModel
    @State var image: UIImage?
    var body: some View {
        VStack(spacing: 0) {

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
