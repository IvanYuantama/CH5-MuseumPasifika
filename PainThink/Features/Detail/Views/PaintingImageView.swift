//
//  PaintingImageView.swift
//  PainThink
//

import SwiftUI

// Draws the artwork, or -- while the images aren't bundled yet -- a temporary
// placeholder image (mr_zeus from Assets). Swap back to real assets once all
// artwork images are bundled in.
// `uiImage` takes priority when provided (e.g. a freshly captured camera photo).
// `contentMode`: .fill (default, crop to frame) or .fit (relative height, natural aspect ratio).
struct PaintingImageView: View {
    let assetName: String?
    var imageURLString: String? = nil
    let fallbackColors: [Color]
    /// Directly captured UIImage (from camera). Takes priority over all other sources.
    var uiImage: UIImage? = nil
    /// .fill crops image to fill the frame; .fit lets height follow the image's natural aspect ratio.
    var contentMode: ContentMode = .fill

    // Only used the first time a given URL is ever loaded — once cached, `artwork`
    // resolves synchronously off `ImageCache` and this never gets set.
    @State private var loadedImage: UIImage?

    private var artwork: Image? {
        if let uiImage { return Image(uiImage: uiImage) }
        if let loadedImage { return Image(uiImage: loadedImage) }
        if let remoteURL, let cached = ImageCache.shared.image(for: remoteURL) {
            return Image(uiImage: cached)
        }
        guard let assetName, UIImage(named: assetName) != nil else { return nil }
        return Image(assetName)
    }

    private var remoteURL: URL? {
        guard let imageURLString else { return nil }
        return URL(string: imageURLString)
    }

    var body: some View {
        Group {
            if let artwork {
                artwork
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                tempPlaceholder
            }
        }
        .task(id: imageURLString) {
            guard uiImage == nil, loadedImage == nil, let remoteURL,
                  ImageCache.shared.image(for: remoteURL) == nil else { return }
            loadedImage = await ImageCache.shared.preload(remoteURL)
        }
    }

    /// Temporary placeholder image shown until real artwork assets are bundled.
    private var tempPlaceholder: some View {
        Image("mr_zeus")
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }
}
