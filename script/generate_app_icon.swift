import CoreGraphics
import Foundation
import ImageIO

guard CommandLine.arguments.count == 5 else {
    fputs(
        "usage: generate_app_icon.swift <app-source.png> <menu-source.png> <app-output.png> <menu-output.png>\n",
        stderr
    )
    exit(2)
}

struct PixelBounds {
    var minX: Int
    var minY: Int
    var maxX: Int
    var maxY: Int

    var cgRect: CGRect {
        CGRect(
            x: minX,
            y: minY,
            width: maxX - minX + 1,
            height: maxY - minY + 1
        )
    }
}

struct RGBAImage {
    let width: Int
    let height: Int
    var pixels: [UInt8]

    func offset(x: Int, y: Int) -> Int {
        (y * width + x) * 4
    }
}

let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
    | CGImageAlphaInfo.premultipliedLast.rawValue

func loadRGBAImage(at url: URL) throws -> RGBAImage {
    guard
        let source = CGImageSourceCreateWithURL(url as CFURL, nil),
        let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "could not decode \(url.path)"]
        )
    }

    let bytesPerRow = image.width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * image.height)
    guard let context = CGContext(
        data: &pixels,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "could not normalize \(url.path)"]
        )
    }
    context.interpolationQuality = .high
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return RGBAImage(width: image.width, height: image.height, pixels: pixels)
}

func isOuterWhite(_ image: RGBAImage, x: Int, y: Int) -> Bool {
    let offset = image.offset(x: x, y: y)
    let red = Int(image.pixels[offset])
    let green = Int(image.pixels[offset + 1])
    let blue = Int(image.pixels[offset + 2])
    let alpha = Int(image.pixels[offset + 3])
    let minimum = min(red, green, blue)
    let maximum = max(red, green, blue)
    let luminance = (299 * red + 587 * green + 114 * blue) / 1000
    return alpha > 2 && (minimum > 246 || (luminance > 230 && maximum - minimum < 12))
}

func removeConnectedWhiteBackground(from image: inout RGBAImage) {
    var visited = [Bool](repeating: false, count: image.width * image.height)
    var queue: [Int] = []

    func enqueue(_ x: Int, _ y: Int) {
        guard x >= 0, x < image.width, y >= 0, y < image.height else { return }
        let index = y * image.width + x
        guard !visited[index], isOuterWhite(image, x: x, y: y) else { return }
        visited[index] = true
        queue.append(index)
    }

    for x in 0..<image.width {
        enqueue(x, 0)
        enqueue(x, image.height - 1)
    }
    for y in 0..<image.height {
        enqueue(0, y)
        enqueue(image.width - 1, y)
    }

    var cursor = 0
    while cursor < queue.count {
        let index = queue[cursor]
        cursor += 1
        let x = index % image.width
        let y = index / image.width
        enqueue(x - 1, y)
        enqueue(x + 1, y)
        enqueue(x, y - 1)
        enqueue(x, y + 1)
    }

    for index in queue {
        let offset = index * 4
        image.pixels[offset] = 0
        image.pixels[offset + 1] = 0
        image.pixels[offset + 2] = 0
        image.pixels[offset + 3] = 0
    }
}

func alphaBounds(in image: RGBAImage, threshold: UInt8 = 5) -> PixelBounds? {
    var result: PixelBounds?
    for y in 0..<image.height {
        for x in 0..<image.width {
            let alpha = image.pixels[image.offset(x: x, y: y) + 3]
            guard alpha > threshold else { continue }
            if var bounds = result {
                bounds.minX = min(bounds.minX, x)
                bounds.minY = min(bounds.minY, y)
                bounds.maxX = max(bounds.maxX, x)
                bounds.maxY = max(bounds.maxY, y)
                result = bounds
            } else {
                result = PixelBounds(minX: x, minY: y, maxX: x, maxY: y)
            }
        }
    }
    return result
}

func cgImage(from image: RGBAImage) throws -> CGImage {
    let data = Data(image.pixels) as CFData
    guard
        let provider = CGDataProvider(data: data),
        let result = CGImage(
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: image.width * 4,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 3,
            userInfo: [NSLocalizedDescriptionKey: "could not create CGImage"]
        )
    }
    return result
}

func renderCentered(
    source: RGBAImage,
    bounds: PixelBounds,
    canvasSize: Int,
    maximumVisibleSize: CGFloat
) throws -> CGImage {
    let sourceImage = try cgImage(from: source)
    guard let cropped = sourceImage.cropping(to: bounds.cgRect) else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 4,
            userInfo: [NSLocalizedDescriptionKey: "could not crop source image"]
        )
    }

    let bytesPerRow = canvasSize * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * canvasSize)
    guard let context = CGContext(
        data: &pixels,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: bytesPerRow,
        space: colorSpace,
        bitmapInfo: bitmapInfo
    ) else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 5,
            userInfo: [NSLocalizedDescriptionKey: "could not create output context"]
        )
    }

    let scale = min(
        maximumVisibleSize / CGFloat(cropped.width),
        maximumVisibleSize / CGFloat(cropped.height)
    )
    let width = CGFloat(cropped.width) * scale
    let height = CGFloat(cropped.height) * scale
    let destination = CGRect(
        x: (CGFloat(canvasSize) - width) / 2,
        y: (CGFloat(canvasSize) - height) / 2,
        width: width,
        height: height
    )
    context.interpolationQuality = .high
    context.draw(cropped, in: destination)
    guard let result = context.makeImage() else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 6,
            userInfo: [NSLocalizedDescriptionKey: "could not render centered image"]
        )
    }
    return result
}

func makeTemplate(from source: RGBAImage) -> RGBAImage {
    func luminance(atX x: Int, y: Int) -> Int {
        let offset = source.offset(x: x, y: y)
        let red = Int(source.pixels[offset])
        let green = Int(source.pixels[offset + 1])
        let blue = Int(source.pixels[offset + 2])
        return (299 * red + 587 * green + 114 * blue) / 1000
    }

    var borderTotal = 0
    var borderCount = 0
    for x in 0..<source.width {
        borderTotal += luminance(atX: x, y: 0)
        borderTotal += luminance(atX: x, y: source.height - 1)
        borderCount += 2
    }
    for y in 1..<(source.height - 1) {
        borderTotal += luminance(atX: 0, y: y)
        borderTotal += luminance(atX: source.width - 1, y: y)
        borderCount += 2
    }
    let borderLuminance = borderTotal / max(1, borderCount)
    let usesDarkBackground = borderLuminance < 128

    var output = RGBAImage(
        width: source.width,
        height: source.height,
        pixels: [UInt8](repeating: 0, count: source.width * source.height * 4)
    )
    for y in 0..<source.height {
        for x in 0..<source.width {
            let offset = source.offset(x: x, y: y)
            let sourceAlpha = Int(source.pixels[offset + 3])
            let pixelLuminance = luminance(atX: x, y: y)
            let rawAlpha: Int
            if usesDarkBackground {
                let range = max(1, 255 - borderLuminance)
                rawAlpha = max(0, pixelLuminance - borderLuminance) * 255 / range
            } else {
                let range = max(1, borderLuminance)
                rawAlpha = max(0, borderLuminance - pixelLuminance) * 255 / range
            }
            let alpha = min(255, rawAlpha * 2) * sourceAlpha / 255
            output.pixels[offset] = 0
            output.pixels[offset + 1] = 0
            output.pixels[offset + 2] = 0
            output.pixels[offset + 3] = UInt8(alpha)
        }
    }
    return output
}

func writePNG(_ image: CGImage, to url: URL) throws {
    try FileManager.default.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    guard let destination = CGImageDestinationCreateWithURL(
        url as CFURL,
        "public.png" as CFString,
        1,
        nil
    ) else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 7,
            userInfo: [NSLocalizedDescriptionKey: "could not create \(url.path)"]
        )
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(
            domain: "CubePetBrandAssets",
            code: 8,
            userInfo: [NSLocalizedDescriptionKey: "could not encode \(url.path)"]
        )
    }
}

let appSourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
let menuSourceURL = URL(fileURLWithPath: CommandLine.arguments[2])
let appOutputURL = URL(fileURLWithPath: CommandLine.arguments[3])
let menuOutputURL = URL(fileURLWithPath: CommandLine.arguments[4])

var appSource = try loadRGBAImage(at: appSourceURL)
removeConnectedWhiteBackground(from: &appSource)
guard let appBounds = alphaBounds(in: appSource) else {
    fputs("app icon source has no visible pixels\n", stderr)
    exit(1)
}
let appOutput = try renderCentered(
    source: appSource,
    bounds: appBounds,
    canvasSize: 1024,
    maximumVisibleSize: 768
)
try writePNG(appOutput, to: appOutputURL)

let menuSource = try loadRGBAImage(at: menuSourceURL)
let menuTemplate = makeTemplate(from: menuSource)
guard let menuBounds = alphaBounds(in: menuTemplate, threshold: 20) else {
    fputs("menu icon source has no visible pixels\n", stderr)
    exit(1)
}
let menuOutput = try renderCentered(
    source: menuTemplate,
    bounds: menuBounds,
    canvasSize: 72,
    maximumVisibleSize: 60
)
try writePNG(menuOutput, to: menuOutputURL)

let appCenterOffsetX = appBounds.cgRect.midX - CGFloat(appSource.width) / 2
let appCenterOffsetY = appBounds.cgRect.midY - CGFloat(appSource.height) / 2
let menuCenterOffsetX = menuBounds.cgRect.midX - CGFloat(menuSource.width) / 2
let menuCenterOffsetY = menuBounds.cgRect.midY - CGFloat(menuSource.height) / 2
print(
    String(
        format: "Centered app artwork (source offset x=%+.1f px, y=%+.1f px) and menu artwork (x=%+.1f px, y=%+.1f px).",
        appCenterOffsetX,
        appCenterOffsetY,
        menuCenterOffsetX,
        menuCenterOffsetY
    )
)
