import SwiftUI
import PhotosUI

struct UploadImageView: View {
    @StateObject private var vm = ImageUploadViewModel()

    var body: some View {
        VStack(spacing: 16) {
            PhotosPicker(
                "Pick up to 5 images",
                selection: $vm.selectedItems,
                maxSelectionCount: 5,
                matching: .images
            )

            Button(vm.isUploading ? "Uploading..." : "Upload") {
                Task { await vm.uploadSelected() }
            }
            .disabled(vm.selectedItems.isEmpty || vm.isUploading)

            if !vm.uploaded.isEmpty {
                Text("Uploaded ✅ (\(vm.uploaded.count))")

                List(vm.uploaded) { file in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(file.filename).font(.subheadline)
                        Text(file.blob_name).font(.caption).textSelection(.enabled)
                    }
                }
                .frame(height: 220)
            }

            if let err = vm.errorMessage {
                Text(err).foregroundStyle(.red)
            }
        }
        .padding()
    }
}

#Preview {
    UploadImageView()
}

