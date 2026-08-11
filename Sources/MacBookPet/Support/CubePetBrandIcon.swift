import AppKit

enum CubePetBrandIcon {
    static func statusImage() -> NSImage {
        let source = Bundle.main.url(
            forResource: "CubePetStatusIcon",
            withExtension: "png"
        ).flatMap(NSImage.init(contentsOf:))
            ?? NSImage(systemSymbolName: "pawprint", accessibilityDescription: "CubePet")
            ?? NSImage(size: NSSize(width: 18, height: 18))

        return preparedStatusImage(from: source)
    }

    static func preparedStatusImage(from source: NSImage) -> NSImage {
        let image = (source.copy() as? NSImage) ?? source
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        image.accessibilityDescription = "CubePet"
        return image
    }
}
