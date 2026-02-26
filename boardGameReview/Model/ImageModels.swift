//
//  ImageModels.swift
//  boardGameReview
//
//  Created by Robert Fusting on 2/21/26.
//

import Foundation

struct UploadImagesResponse: Decodable {
    let count: Int
    let uploads: [UploadedFile]

    struct UploadedFile: Decodable, Identifiable {
        let filename: String
        let content_type: String
        let blob_name: String
        let bytes: Int

        var id: String { blob_name }
    }
}
