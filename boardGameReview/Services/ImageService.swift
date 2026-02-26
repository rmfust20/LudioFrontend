//
//  ImageService.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/21/26.
//

import Foundation
import PhotosUI
import SwiftUI

struct ImageService {
    
    let client: APIClient
    let baseURL: String
    
    init(client: APIClient = APIClient.shared) {
        self.client = client
        self.baseURL = "https://tabulusapp.bravegrass-0afbc7b6.westus2.azurecontainerapps.io"
    }
    
    func uploadSelectedImages(selectedImages : [PhotosPickerItem]) async throws -> [UploadImagesResponse.UploadedFile] {
        do {
            // Load up to 5 (PhotosPicker enforces, but we’ll be safe)
            let items = Array(selectedImages.prefix(5))

            // Load all image datas
            var files: [(data: Data, mimeType: String, filename: String)] = []
            files.reserveCapacity(items.count)

            for (idx, item) in items.enumerated() {
                guard let data = try await item.loadTransferable(type: Data.self) else {
                    throw NSError(domain: "Upload", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Could not load image data for item \(idx + 1)"
                    ])
                }

                if data.count > 8 * 1024 * 1024 {
                    throw NSError(domain: "Upload", code: 0, userInfo: [
                        NSLocalizedDescriptionKey: "Image \(idx + 1) is larger than 8MB"
                    ])
                }

                let mime = guessMimeType(from: data) ?? "image/jpeg"
                let ext = mime == "image/png" ? "png" : (mime == "image/webp" ? "webp" : "jpg")
                let filename = "upload-\(UUID().uuidString).\(ext)"

                files.append((data: data, mimeType: mime, filename: filename))
            }

            // Upload as multipart with multiple "files" parts
            let resp = try await uploadImages(files: files)
            let uploaded = resp.uploads
            return uploaded

        } catch {
            throw error
        }
    }
    
    private func uploadImages(files: [(data: Data, mimeType: String, filename: String)]) async throws -> UploadImagesResponse {
        var components = URLComponents(string: baseURL)
        components?.path = "/images/upload/"
        guard let url = components?.url else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // IMPORTANT: FastAPI expects field name "files" now (list[UploadFile])
        let body = makeMultipartBody(
            boundary: boundary,
            fieldName: "files",
            files: files
        )

        request.httpBody = body
        request.setValue(String(body.count), forHTTPHeaderField: "Content-Length")

        let (respData, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "Upload", code: 0, userInfo: [NSLocalizedDescriptionKey: "No HTTP response"])
        }

        guard (200..<300).contains(http.statusCode) else {
            let text = String(data: respData, encoding: .utf8) ?? "<no body>"
            throw NSError(domain: "Upload", code: http.statusCode, userInfo: [
                NSLocalizedDescriptionKey: "Upload failed (\(http.statusCode)): \(text)"
            ])
        }

        return try JSONDecoder().decode(UploadImagesResponse.self, from: respData)
    }
    
    private func makeMultipartBody(
        boundary: String,
        fieldName: String,
        files: [(data: Data, mimeType: String, filename: String)]
    ) -> Data {
        var body = Data()
        func append(_ s: String) { body.append(Data(s.utf8)) }

        for file in files {
            append("--\(boundary)\r\n")
            append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(file.filename)\"\r\n")
            append("Content-Type: \(file.mimeType)\r\n\r\n")
            body.append(file.data)
            append("\r\n")
        }

        append("--\(boundary)--\r\n")
        return body
    }
    
    private func guessMimeType(from data: Data) -> String? {
        if data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) { return "image/png" }
        if data.starts(with: [0xFF, 0xD8, 0xFF]) { return "image/jpeg" }
        if data.count >= 12 {
            let riff = data.prefix(4)
            let webp = data.dropFirst(8).prefix(4)
            if riff == Data([0x52, 0x49, 0x46, 0x46]) && webp == Data([0x57, 0x45, 0x42, 0x50]) {
                return "image/webp"
            }
        }
        return nil
    }
}

