import AppKit
import Foundation

struct FoodFilePayload: Codable {
    static let currentVersion = 1

    let version: Int
    let foodID: String
    let token: String
}

struct CreatedDesktopFood {
    let url: URL
    let payload: FoodFilePayload
}

enum DesktopFoodFile {
    static let pathExtension = "mbpetfood"
    private static let maximumPayloadSize = 4_096

    static func create(food: FoodDefinition, displayName: String) throws -> CreatedDesktopFood {
        let fileManager = FileManager.default
        guard let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let payload = FoodFilePayload(
            version: FoodFilePayload.currentVersion,
            foodID: food.id,
            token: UUID().uuidString
        )
        let data = try JSONEncoder().encode(payload)
        let fileURL = availableURL(named: displayName, in: desktopURL, fileManager: fileManager)
        try data.write(to: fileURL, options: .withoutOverwriting)

        if !NSWorkspace.shared.setIcon(icon(for: food.name), forFile: fileURL.path) {
            NSLog("MacBookPet could not set the food icon for %@", fileURL.path)
        }

        return CreatedDesktopFood(url: fileURL, payload: payload)
    }

    static func isFoodFile(_ url: URL) -> Bool {
        url.pathExtension.caseInsensitiveCompare(pathExtension) == .orderedSame
    }

    static func payload(at url: URL) -> FoodFilePayload? {
        guard isFoodFile(url) else { return nil }

        guard
            let values = try? url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
            values.isRegularFile == true,
            let fileSize = values.fileSize,
            fileSize <= maximumPayloadSize,
            let data = try? Data(contentsOf: url),
            let payload = try? JSONDecoder().decode(FoodFilePayload.self, from: data),
            payload.version == FoodFilePayload.currentVersion
        else { return nil }

        return payload
    }

    static func remove(_ url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            NSLog("MacBookPet could not remove consumed food %@: %@", url.path, error.localizedDescription)
        }
    }

    private static func availableURL(named displayName: String, in folderURL: URL, fileManager: FileManager) -> URL {
        var index = 1

        while true {
            let suffix = index == 1 ? "" : " \(index)"
            let candidate = folderURL
                .appendingPathComponent("\(displayName)\(suffix)")
                .appendingPathExtension(pathExtension)

            if !fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
            index += 1
        }
    }

    static func icon(for name: FoodName) -> NSImage {
        switch name {
        case .smallCookie:
            cookieIcon()
        case .energyBar:
            energyBarIcon()
        case .petCola:
            petColaIcon()
        case .fishShapedPastry:
            bundledIcon(named: "FishShapedPastry", fallback: cookieIcon)
        case .puddingCup:
            bundledIcon(named: "PuddingCup", fallback: energyBarIcon)
        case .threeColorDango:
            bundledIcon(named: "ThreeColorDango", fallback: cookieIcon)
        }
    }

    private static func bundledIcon(named resourceName: String, fallback: () -> NSImage) -> NSImage {
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            image.isTemplate = false
            return image
        }

        return fallback()
    }

    private static func makeIcon(drawing: () -> Void) -> NSImage {
        // 256 px is more than enough for a Finder desktop icon and keeps the
        // generated custom icon light when several foods are placed on disk.
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size)
        image.lockFocus()

        NSGraphicsContext.current?.cgContext.scaleBy(x: 0.5, y: 0.5)

        NSColor.clear.setFill()
        NSRect(origin: .zero, size: size).fill()

        drawing()

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func cookieIcon() -> NSImage {
        makeIcon {
            let cookieRect = NSRect(x: 50, y: 50, width: 412, height: 412)
            let outline = NSColor(calibratedRed: 0.28, green: 0.13, blue: 0.07, alpha: 1)
            outline.setFill()
            NSBezierPath(ovalIn: cookieRect).fill()

            let dough = cookieRect.insetBy(dx: 20, dy: 20)
            NSColor(calibratedRed: 0.96, green: 0.67, blue: 0.30, alpha: 1).setFill()
            NSBezierPath(ovalIn: dough).fill()

            NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.46, alpha: 1).setStroke()
            let rim = NSBezierPath(ovalIn: dough.insetBy(dx: 24, dy: 24))
            rim.lineWidth = 12
            rim.stroke()

            outline.setFill()
            for point in [
                NSPoint(x: 165, y: 335), NSPoint(x: 310, y: 360),
                NSPoint(x: 370, y: 250), NSPoint(x: 255, y: 260),
                NSPoint(x: 145, y: 205), NSPoint(x: 300, y: 135)
            ] {
                NSBezierPath(ovalIn: NSRect(x: point.x - 21, y: point.y - 21, width: 42, height: 42)).fill()
            }

            NSColor(calibratedRed: 1.0, green: 0.88, blue: 0.58, alpha: 0.9).setFill()
            for rect in [NSRect(x: 132, y: 294, width: 46, height: 20), NSRect(x: 280, y: 190, width: 30, height: 15)] {
                NSBezierPath(roundedRect: rect, xRadius: 10, yRadius: 10).fill()
            }
        }
    }

    private static func energyBarIcon() -> NSImage {
        makeIcon {
            let barRect = NSRect(x: 48, y: 116, width: 416, height: 280)
            let outline = NSColor(calibratedRed: 0.13, green: 0.17, blue: 0.24, alpha: 1)
            outline.setFill()
            NSBezierPath(roundedRect: barRect, xRadius: 42, yRadius: 42).fill()

            let wrapper = barRect.insetBy(dx: 18, dy: 18)
            NSColor(calibratedRed: 0.25, green: 0.76, blue: 0.70, alpha: 1).setFill()
            NSBezierPath(roundedRect: wrapper, xRadius: 30, yRadius: 30).fill()

            NSColor(calibratedRed: 0.13, green: 0.53, blue: 0.54, alpha: 1).setFill()
            for x in [wrapper.minX + 28, wrapper.maxX - 62] {
                NSBezierPath(roundedRect: NSRect(x: x, y: wrapper.minY + 8, width: 34, height: wrapper.height - 16), xRadius: 15, yRadius: 15).fill()
            }

            NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.24, alpha: 1).setFill()
            let bolt = NSBezierPath()
            bolt.move(to: NSPoint(x: 278, y: 348))
            bolt.line(to: NSPoint(x: 204, y: 252))
            bolt.line(to: NSPoint(x: 254, y: 252))
            bolt.line(to: NSPoint(x: 222, y: 164))
            bolt.line(to: NSPoint(x: 326, y: 280))
            bolt.line(to: NSPoint(x: 274, y: 280))
            bolt.close()
            bolt.fill()

            NSColor(calibratedRed: 0.76, green: 0.96, blue: 0.88, alpha: 0.9).setStroke()
            let shine = NSBezierPath()
            shine.move(to: NSPoint(x: 108, y: 346))
            shine.line(to: NSPoint(x: 196, y: 346))
            shine.lineWidth = 12
            shine.lineCapStyle = .round
            shine.stroke()
        }
    }

    private static func petColaIcon() -> NSImage {
        bundledIcon(named: "PetCola") {
            makeIcon {
                let outline = NSColor(calibratedRed: 0.17, green: 0.12, blue: 0.15, alpha: 1)
                let bottle = NSBezierPath(roundedRect: NSRect(x: 126, y: 56, width: 260, height: 344), xRadius: 62, yRadius: 62)
                outline.setFill()
                bottle.fill()

                let label = NSRect(x: 144, y: 128, width: 224, height: 178)
                NSColor(calibratedRed: 0.95, green: 0.34, blue: 0.31, alpha: 1).setFill()
                NSBezierPath(roundedRect: label, xRadius: 38, yRadius: 38).fill()

                NSColor(calibratedRed: 1.0, green: 0.84, blue: 0.30, alpha: 1).setFill()
                NSBezierPath(roundedRect: NSRect(x: 177, y: 386, width: 158, height: 48), xRadius: 18, yRadius: 18).fill()
                outline.setStroke()
                let capLine = NSBezierPath()
                capLine.move(to: NSPoint(x: 190, y: 410))
                capLine.line(to: NSPoint(x: 322, y: 410))
                capLine.lineWidth = 8
                capLine.stroke()

                NSColor.white.setFill()
                let paw = NSBezierPath()
                paw.appendOval(in: NSRect(x: 211, y: 164, width: 92, height: 78))
                for toe in [NSRect(x: 187, y: 236, width: 40, height: 48), NSRect(x: 236, y: 254, width: 40, height: 50), NSRect(x: 285, y: 236, width: 40, height: 48)] {
                    paw.appendOval(in: toe)
                }
                paw.fill()

                NSColor(calibratedRed: 1.0, green: 0.62, blue: 0.55, alpha: 0.95).setStroke()
                let shine = NSBezierPath()
                shine.move(to: NSPoint(x: 158, y: 334))
                shine.line(to: NSPoint(x: 185, y: 362))
                shine.lineWidth = 14
                shine.lineCapStyle = .round
                shine.stroke()
            }
        }
    }
}
