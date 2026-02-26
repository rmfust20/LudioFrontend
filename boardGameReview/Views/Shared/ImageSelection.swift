//
//  ImageSelection.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/21/26.
//

import SwiftUI
import PhotosUI

struct ImageSelection: View {
    @StateObject private var imageViewModel = ImageUploadViewModel()
    
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
        ZStack(alignment: .bottomTrailing) {
            Image(uiImage: tileImage)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .clipped()
                .padding()
                .padding(10) // space so background shows around image
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial) // or .fill(Color(.secondarySystemBackground))
                )
            Button {
                onRemove()
            } label: {
                Image(systemName: "x.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .opacity(0.5)
            }.buttonStyle(.plain)
        }
    }
}

struct AddImageView: View {
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .clipped()
                .cornerRadius(8)
                .opacity(0.1)
            Button {
                //add image
            } label: {
                Image(systemName: "plus.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .opacity(0.5)
            }
            .buttonStyle(.plain)
            .disabled(true)
                
        }
    }
}

#Preview {
    ImageSelection()
}
