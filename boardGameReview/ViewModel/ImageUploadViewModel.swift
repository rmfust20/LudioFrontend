import SwiftUI
import PhotosUI
import CryptoKit

final class ImageUploadViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var isUploading = false
    @Published var uploaded: [UploadImagesResponse.UploadedFile] = []
    @Published var errorMessage: String?
    @Published var images: [UIImage] = []
    private var imageCache: [PhotosPickerItem: UIImage] = [:]
    let maxImages = 5
    let imageService: ImageService = ImageService()
    
    @MainActor
    func uploadSelected(auth: Auth) async {
        guard !selectedItems.isEmpty else { return }
        errorMessage = nil
        uploaded = []
        isUploading = true
        defer { isUploading = false }
        
        do {
            uploaded = try await imageService.uploadSelectedImages(selectedImages: selectedItems, accessToken: auth.accessToken ?? "")
        }
        
        catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }
    }
    
    func getImageCount() -> Int {
        return selectedItems.count
    }
    
    func onRemove(at index: Int) {
        guard index < selectedItems.count else { return }
        let removed = selectedItems.remove(at: index)
        imageCache.removeValue(forKey: removed)
        rebuildImages()
    }

    @MainActor
    func DetectPhotoChanges(old: [PhotosPickerItem], new: [PhotosPickerItem]) async {
        // Drop cached entries for items no longer selected.
        let newSet = Set(new)
        for key in imageCache.keys where !newSet.contains(key) {
            imageCache.removeValue(forKey: key)
        }

        // Load any items we haven't cached yet.
        for item in new where imageCache[item] == nil {
            do {
                if let data = try await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    imageCache[item] = uiImage
                }
            } catch {
            }
        }

        rebuildImages()
    }

    private func rebuildImages() {
        images = selectedItems.compactMap { imageCache[$0] }
    }
}


