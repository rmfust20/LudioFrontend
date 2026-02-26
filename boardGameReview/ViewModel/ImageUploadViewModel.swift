import SwiftUI
import PhotosUI
import CryptoKit

final class ImageUploadViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var isUploading = false
    @Published var uploaded: [UploadImagesResponse.UploadedFile] = []
    @Published var errorMessage: String?
    @Published var images: [UIImage] = []
    private var loadedIDs = Set<Int>()  // itemIdentifier strings
    let maxImages = 5
    let imageService: ImageService = ImageService()
    
    @MainActor
    func uploadSelected() async {
        guard !selectedItems.isEmpty else { return }
        errorMessage = nil
        uploaded = []
        isUploading = true
        defer { isUploading = false }
        
        do {
            uploaded = try await imageService.uploadSelectedImages(selectedImages: selectedItems)
        }
        
        catch {
            errorMessage = "Upload failed: \(error.localizedDescription)"
        }
    }
    
    func getImageCount() -> Int {
        return selectedItems.count
    }
    
    func onRemove(at index: Int) {
        guard index < images.count else { return }
        let removedID = selectedItems[index].hashValue
        selectedItems.remove(at: index)
        images.remove(at: index)
        loadedIDs.remove(removedID)
    }
    
    @MainActor
    func DetectPhotoChanges(old : [PhotosPickerItem], new: [PhotosPickerItem]) async {
        // old has what was previously selected, new has what is currently selected
        let diff = Set(new.map { $0.hashValue}).subtracting(loadedIDs)
        do {
            for i in (0..<selectedItems.count) {
                    if diff.contains(selectedItems[i].hashValue) {
                        if let data = try await selectedItems[i].loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                images.append(uiImage)
                        }
                    }
                }
            }
            
            for item in new {
                let fingerprint = item.hashValue
                loadedIDs.insert(fingerprint)
            }
        } catch {
            print("Error loading images: \(error)")
        }
    }
}


