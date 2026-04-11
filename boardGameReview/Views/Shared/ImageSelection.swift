//
//  ImageSelection.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/21/26.
//

import SwiftUI
import PhotosUI

struct ImageSelection: View {
    @ObservedObject var imageViewModel : ImageUploadViewModel
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(0..<5){ index in
                    if index < imageViewModel.images.count {
                        ImageTile(onRemove: {
                            imageViewModel.onRemove(at: index)
                        }, tileImage: imageViewModel.images[index])
                    }
                }
                PhotosPicker(
                    selection: $imageViewModel.selectedItems,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    AddImageView()
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.black)
                .tint(.blue)
                .onChange(of: imageViewModel.selectedItems) { oldValue, newValue in
                    Task {
                        await imageViewModel.DetectPhotoChanges(old: oldValue, new: newValue)
                    }
                }
            }
        }
    }
}

struct ImageTile: View {
    let onRemove: () -> Void
    let tileImage: UIImage
    var body: some View {
        VStack(alignment: .trailing) {
            Image(uiImage: tileImage)
                .resizable()
                .scaledToFill()
                .aspectRatio(1, contentMode: .fit)  // square tiles
                .frame(width: 170, height: 150)
                .clipped()
                .cornerRadius(12)
                .overlay(alignment: .topTrailing) {
                    Button {
                        onRemove()
                    } label: {
                        Image(systemName: "x.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundStyle(Color.white)
                    }.buttonStyle(.plain)
                }
        }
    }
}

struct AddImageView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFill()
                .aspectRatio(1, contentMode: .fit)
                .frame(width: 170, height: 150)
                .clipped()
                .cornerRadius(12)
                .foregroundStyle(Color.white)
                .opacity(0.4)
            Button {
                //add image
            } label: {
                Image(systemName: "plus.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    //.padding(.trailing, 4)
                    .opacity(0.5)
            }
            .buttonStyle(.plain)
            .disabled(true)
                
        }
    }
}

#Preview {
    ImageSelection(imageViewModel: ImageUploadViewModel())
}
