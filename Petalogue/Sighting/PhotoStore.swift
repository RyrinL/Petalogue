//
//  PhotoStore.swift
//  Petalogue
//
//  Writes scan photos as JPEG into the Documents directory and returns
//  filenames only — SwiftData stores the filename, never the image Data.
//

import UIKit

protocol PhotoStoring {
    func save(_ image: UIImage, for speciesID: String) throws -> (photo: String, thumb: String)
    func load(filename: String) -> UIImage?
    func delete(filename: String) throws
}

final class PhotoStore: PhotoStoring {
    static let shared = PhotoStore()

    private let fileManager: FileManager
    private let thumbnailMaxDimension: CGFloat = 300
    private let fullQuality: CGFloat = 0.85
    private let thumbQuality: CGFloat = 0.7

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    enum PhotoStoreError: Error {
        case jpegEncodingFailed
        case documentsDirectoryUnavailable
    }

    private var documentsURL: URL {
        get throws {
            guard let url = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw PhotoStoreError.documentsDirectoryUnavailable
            }
            return url
        }
    }

    func save(_ image: UIImage, for speciesID: String) throws -> (photo: String, thumb: String) {
        let base = "\(speciesID)-\(UUID().uuidString)"
        let photoName = "\(base).jpg"
        let thumbName = "\(base)-thumb.jpg"

        guard let photoData = image.jpegData(compressionQuality: fullQuality) else {
            throw PhotoStoreError.jpegEncodingFailed
        }
        let thumbnail = image.downscaled(toMaxDimension: thumbnailMaxDimension)
        guard let thumbData = thumbnail.jpegData(compressionQuality: thumbQuality) else {
            throw PhotoStoreError.jpegEncodingFailed
        }

        let dir = try documentsURL
        try photoData.write(to: dir.appendingPathComponent(photoName), options: .atomic)
        try thumbData.write(to: dir.appendingPathComponent(thumbName), options: .atomic)

        return (photoName, thumbName)
    }

    func load(filename: String) -> UIImage? {
        guard let dir = try? documentsURL else { return nil }
        let url = dir.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func delete(filename: String) throws {
        let url = try documentsURL.appendingPathComponent(filename)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }
}

private extension UIImage {
    /// Aspect-fit downscale; returns self if already small enough.
    func downscaled(toMaxDimension maxDimension: CGFloat) -> UIImage {
        let longestSide = max(size.width, size.height)
        guard longestSide > maxDimension else { return self }
        let scale = maxDimension / longestSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
