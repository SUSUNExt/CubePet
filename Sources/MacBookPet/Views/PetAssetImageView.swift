import AppKit
import SwiftUI

struct PetAssetImageView<Placeholder: View>: View {
    let url: URL?
    let purpose: PetImagePurpose
    let contentMode: ContentMode
    let placeholder: Placeholder

    @State private var thumbnail: NSImage?
    @State private var loadedThumbnailKey: String?

    init(
        url: URL?,
        purpose: PetImagePurpose,
        contentMode: ContentMode = .fit,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.url = url
        self.purpose = purpose
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            switch purpose {
            case .fullResolution:
                if let url, let image = PetImportedImageCache.image(for: url) {
                    rendered(image)
                } else {
                    placeholder
                }
            case .listThumbnail:
                ZStack {
                    // Keep a concrete layout node alive even when the caller's
                    // placeholder is EmptyView. Otherwise SwiftUI can collapse
                    // the view before `.task` starts, leaving layered eyes
                    // visible without the asynchronously loaded pet body.
                    Color.clear

                    if loadedThumbnailKey == thumbnailKey, let thumbnail {
                        rendered(thumbnail)
                    } else {
                        placeholder
                    }
                }
            }
        }
        .task(id: thumbnailKey) {
            await loadThumbnailIfNeeded()
        }
    }

    @ViewBuilder
    private func rendered(_ image: NSImage) -> some View {
        if contentMode == .fill {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFill()
        } else {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
        }
    }

    private var thumbnailKey: String? {
        guard let url, case let .listThumbnail(maxPixelSize) = purpose else { return nil }
        return "\(url.standardizedFileURL.path)|\(maxPixelSize)"
    }

    @MainActor
    private func loadThumbnailIfNeeded() async {
        guard
            let url,
            case let .listThumbnail(maxPixelSize) = purpose,
            let thumbnailKey
        else {
            thumbnail = nil
            loadedThumbnailKey = nil
            return
        }

        if let cached = PetListThumbnailCache.cachedThumbnail(
            for: url,
            maxPixelSize: maxPixelSize
        ) {
            thumbnail = NSImage(cgImage: cached, size: .zero)
            loadedThumbnailKey = thumbnailKey
            return
        }

        let generation = PetListThumbnailCache.currentGeneration()
        let downsampled = await Task.detached(priority: .userInitiated) {
            PetListThumbnailCache.thumbnail(
                for: url,
                maxPixelSize: maxPixelSize,
                generation: generation
            )
        }.value
        guard !Task.isCancelled, let downsampled else { return }

        thumbnail = NSImage(cgImage: downsampled, size: .zero)
        loadedThumbnailKey = thumbnailKey
    }
}

extension PetAssetImageView where Placeholder == EmptyView {
    init(
        url: URL?,
        purpose: PetImagePurpose,
        contentMode: ContentMode = .fit
    ) {
        self.init(url: url, purpose: purpose, contentMode: contentMode) {
            EmptyView()
        }
    }
}
