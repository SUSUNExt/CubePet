import CoreGraphics
import Foundation

struct PetDecorationPosition: Codable, Equatable, Hashable {
    let xFraction: Double
    let yFraction: Double

    init(xFraction: Double, yFraction: Double) {
        self.xFraction = Self.clamped(xFraction)
        self.yFraction = Self.clamped(yFraction)
    }

    init(location: CGPoint, in size: CGSize) {
        guard size.width > 0, size.height > 0 else {
            self.init(xFraction: 0.5, yFraction: 0.5)
            return
        }

        self.init(
            xFraction: Double(location.x / size.width),
            yFraction: Double(location.y / size.height)
        )
    }

    func point(in size: CGSize) -> CGPoint {
        CGPoint(
            x: CGFloat(xFraction) * size.width,
            y: CGFloat(yFraction) * size.height
        )
    }

    private static func clamped(_ value: Double) -> Double {
        guard value.isFinite else { return 0.5 }
        return min(max(value, 0), 1)
    }
}

struct PetEquippedDecoration: Codable, Equatable, Hashable, Identifiable {
    static let minimumScale = 0.35
    static let maximumScale = 2.2

    let petID: String
    let skinID: String
    let category: PetDecorationCategory
    let itemID: String
    var position: PetDecorationPosition
    var scale: Double

    init(
        petID: String,
        skinID: String,
        category: PetDecorationCategory,
        itemID: String,
        position: PetDecorationPosition,
        scale: Double = 1
    ) {
        self.petID = petID
        self.skinID = skinID
        self.category = category
        self.itemID = itemID
        self.position = position
        self.scale = Self.clampedScale(scale)
    }

    var id: String {
        Self.slotID(petID: petID, skinID: skinID, category: category)
    }

    static func slotID(
        petID: String,
        skinID: String,
        category: PetDecorationCategory
    ) -> String {
        "\(petID)::\(skinID)::\(category.rawValue)"
    }

    static func clampedScale(_ value: Double) -> Double {
        guard value.isFinite else { return 1 }
        return min(max(value, minimumScale), maximumScale)
    }

    private enum CodingKeys: String, CodingKey {
        case petID
        case skinID
        case category
        case itemID
        case position
        case scale
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            petID: try container.decode(String.self, forKey: .petID),
            skinID: try container.decode(String.self, forKey: .skinID),
            category: try container.decode(PetDecorationCategory.self, forKey: .category),
            itemID: try container.decode(String.self, forKey: .itemID),
            position: try container.decode(PetDecorationPosition.self, forKey: .position),
            scale: try container.decodeIfPresent(Double.self, forKey: .scale) ?? 1
        )
    }
}
