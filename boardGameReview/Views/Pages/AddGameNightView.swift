import SwiftUI

struct AddGameNightView: View {
    let userID: Int
    @State private var isPresented: Bool = false
    @State private var addFriendsPresented: Bool = false
    @State var selectedBoardGameID: Int? = nil
    @StateObject private var gameNightViewModel = GameNightViewModel()
    @State private var placeholderText: String = "What happened?"
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var auth: Auth
    @StateObject private var imageUploadViewModel = ImageUploadViewModel()

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // Add Game row
                    Button {
                        isPresented.toggle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(Color("PrimaryButton"))
                            Text("Add Game")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color("MutedText"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                    // Selected games
                    ForEach(gameNightViewModel.selectedGames, id: \.id) { game in
                        AddGameView(
                            boardGame: game,
                            gameNightViewModel: gameNightViewModel,
                            image: ImageCache.shared.getImage(for: game.id)
                        )
                        .onAppear {
                            Task {
                                await gameNightViewModel.updateImageCache(boardGame: game)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }

                    // Description editor
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $gameNightViewModel.description)
                            .scrollContentBackground(.hidden)
                            .background(Color("CardSurface"))
                            .foregroundStyle(.white)
                            .font(.system(size: 15))
                            .frame(height: 160)
                            .padding(12)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        if gameNightViewModel.description.isEmpty {
                            Text("What happened?")
                                .font(.system(size: 15))
                                .foregroundStyle(Color("MutedText"))
                                .padding(.top, 20)
                                .padding(.leading, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Tag Friends row
                    Button {
                        addFriendsPresented.toggle()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(Color("PrimaryButton"))
                            Text("Tag Friends")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundStyle(Color("MutedText"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .background(Color("CardSurface"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Image picker
                    ImageSelection(imageViewModel: imageUploadViewModel)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    Spacer(minLength: 40)
                }
            }
            .fullScreenCover(isPresented: $isPresented) {
                SearchView(isPresented: $isPresented, selectedBoardGameID: $selectedBoardGameID)
                    .onChange(of: selectedBoardGameID) {
                        Task {
                            let game = await gameNightViewModel.fetchBoardGame(selectedBoardGameID ?? -1)
                            if let game {
                                gameNightViewModel.selectedGames.append(game)
                            }
                            isPresented.toggle()
                        }
                    }
            }
            .fullScreenCover(isPresented: $addFriendsPresented) {
                TagFriends(winnerCaller: nil, gameNightViewModel: gameNightViewModel, isPresented: $addFriendsPresented)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await imageUploadViewModel.uploadSelected(auth: auth)
                        await gameNightViewModel.uploadGameNight(
                            auth: auth, images: imageUploadViewModel.uploaded
                        )
                    }
                } label: {
                    Text("Save")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color("PrimaryButton"))
                }
            }
        }
    }
}

// MARK: - Add Game View

struct AddGameView: View {
    let boardGame: BoardGameModel
    @ObservedObject var gameNightViewModel: GameNightViewModel
    @State var image: UIImage?
    @State var addFriendsPresented: Bool = false
    @State var durationPresented: Bool = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Group {
                        if let img = image {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.12))
                                .overlay(Image(systemName: "photo").foregroundStyle(Color.gray.opacity(0.3)))
                        }
                    }
                    .frame(width: 72, height: 72)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(boardGame.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)

                        HStack(spacing: 10) {
                            Button {
                                addFriendsPresented.toggle()
                            } label: {
                                Text(gameNightViewModel.selectedWinners[boardGame.id] != nil ? "Change Winner(s)" : "Add Winner(s)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color("PrimaryButton"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("PrimaryButton").opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)

                            Button {
                                durationPresented.toggle()
                            } label: {
                                Text(gameNightViewModel.gameNightDurations[boardGame.id] != nil ? "Change Duration" : "Add Duration")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(Color("PrimaryButton"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color("PrimaryButton").opacity(0.15))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(Color("CardSurface"))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                AddDurationView(gameNightViewModel: gameNightViewModel, gameID: boardGame.id, isPresented: $durationPresented)
            }
        }
        .fullScreenCover(isPresented: $addFriendsPresented) {
            TagFriends(winnerCaller: boardGame.id, gameNightViewModel: gameNightViewModel, isPresented: $addFriendsPresented)
        }
    }
}

// MARK: - Add Duration View

struct AddDurationView: View {
    @ObservedObject var gameNightViewModel: GameNightViewModel
    let gameID: Int
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            VStack(spacing: 0) {
                Text("Select Duration")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.vertical, 14)

                Rectangle()
                    .fill(.white.opacity(0.08))
                    .frame(maxWidth: .infinity, maxHeight: 1)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(1..<21, id: \.self) { index in
                            let time = (index * 30) / 60
                            let remainder = (index * 30) % 60
                            let label: String = {
                                if time == 0 { return "\(remainder) minutes" }
                                else if remainder == 0 { return "\(time) hours" }
                                else if time < 10 { return "\(time) hours \(remainder) minutes" }
                                else { return "\(time) hours +" }
                            }()

                            Button {
                                isPresented.toggle()
                                gameNightViewModel.gameNightDurations[gameID] = time + remainder
                            } label: {
                                Text(label)
                                    .font(.system(size: 14))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)

                            Rectangle()
                                .fill(.white.opacity(0.08))
                                .frame(maxWidth: .infinity, maxHeight: 1)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .frame(height: 300)
            .background(Color("CardSurface"))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.top, 8)
        }
    }
}

// MARK: - Tag Friends

struct TagFriends: View {
    let winnerCaller: Int?
    @ObservedObject var gameNightViewModel: GameNightViewModel
    @Binding var isPresented: Bool
    @State var searchText: String = ""
    @State var taggedFriends: [String] = []

    var body: some View {
        ZStack {
            Color("CharcoalBackground").ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button {
                        isPresented.toggle()
                    } label: {
                        Text("Done")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color("PrimaryButton"))
                    }
                    .padding(.trailing, 20)
                }
                .padding(.vertical, 14)

                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Color("MutedText"))
                        .padding(.leading, 12)
                    Button {} label: {
                        TextField("Tag Friends", text: $searchText)
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.leading)
                            .onChange(of: searchText) {
                                gameNightViewModel.filterFriends(searchText: searchText)
                            }
                    }
                    .padding(.vertical, 10)
                    .padding(.trailing, 12)
                }
                .background(Color("CardSurface"))
                .clipShape(Capsule())
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        ForEach(gameNightViewModel.filteredFriends) { friend in
                            TaggedFriendListView(
                                winnerCaller: winnerCaller,
                                friendName: friend.username,
                                friendID: friend.id,
                                isSelected: gameNightViewModel.handleIsSelected(friendID: friend.id, winnerCaller: winnerCaller),
                                onSelect: {
                                    gameNightViewModel.resolveToggle(friend.id, winnerCaller: winnerCaller)
                                }
                            )
                            Rectangle()
                                .fill(.white.opacity(0.06))
                                .frame(maxWidth: .infinity, maxHeight: 1)
                                .padding(.horizontal, 16)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await gameNightViewModel.getUserFriends(userID: 1)
            }
        }
    }
}

// MARK: - Tagged Friend List View

struct TaggedFriendListView: View {
    let winnerCaller: Int?
    @State var friendImage: UIImage?
    @State var friendName: String
    @State var friendID: Int
    @State var isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundStyle(Color("MutedText"))

            Text(friendName)
                .font(.system(size: 15))
                .foregroundStyle(.white)

            Spacer()

            Button {
                onSelect()
                isSelected.toggle()
            } label: {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundStyle(Color("PrimaryButton"))
                } else {
                    Text("Add")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Color("PrimaryButton"))
                        .clipShape(Capsule())
                }
            }
            .buttonStyle(.plain)
            .padding(.trailing, 16)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    AddGameNightView(userID: 1)
}
