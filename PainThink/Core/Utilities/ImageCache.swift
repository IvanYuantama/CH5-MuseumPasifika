//
//  ImageCache.swift
//  PainThink
//

import UIKit
import CryptoKit

// Two-tier cache keyed by URL: an in-memory NSCache for the running process,
// backed by a disk cache under Caches/ so a relaunch doesn't have to
// re-download images the app already has — they load instantly, like they
// were on-device all along.
final class ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskDirectory: URL
    private let fileManager = FileManager.default

    private init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskDirectory = caches.appendingPathComponent("PaintingImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskDirectory, withIntermediateDirectories: true)
    }

    // Synchronous on purpose: called directly from a view's body for a
    // zero-flash render on a cache hit. A disk hit is a single small-file
    // read, same cost class as the UIImage(named:) lookups already done
    // inline elsewhere in this app.
    func image(for url: URL) -> UIImage? {
        let key = cacheKey(for: url)
        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }
        guard let data = try? Data(contentsOf: diskPath(for: key)),
              let image = UIImage(data: data) else {
            return nil
        }
        memoryCache.setObject(image, forKey: key as NSString)
        return image
    }

    func store(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url)
        memoryCache.setObject(image, forKey: key as NSString)
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        try? data.write(to: diskPath(for: key), options: .atomic)
    }

    @discardableResult
    func preload(_ url: URL) async -> UIImage? {
        if let cached = image(for: url) { return cached }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let image = UIImage(data: data) else { return nil }
        store(image, for: url)
        return image
    }

    // SHA256 rather than String.hashValue: Swift's built-in hash is randomized
    // per process launch, so it can't be used as a stable disk filename.
    private func cacheKey(for url: URL) -> String {
        SHA256.hash(data: Data(url.absoluteString.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    private func diskPath(for key: String) -> URL {
        diskDirectory.appendingPathComponent(key)
    }
}
