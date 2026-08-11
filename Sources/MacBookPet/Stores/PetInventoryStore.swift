import Combine
import Foundation

struct PetInventoryFoodUseResult: Equatable {
    let experience: Int
    let satiety: Int
}

@MainActor
final class PetInventoryStore: ObservableObject {
    private static let quantitiesKey = "MacBookPet.petInventoryQuantities"
    private static let equippedDecorationsKey = "MacBookPet.equippedPetDecorations"

    @Published private(set) var quantitiesByItemID: [String: Int]
    @Published private(set) var equippedDecorationsBySlot: [String: PetEquippedDecoration]

    private let defaults: UserDefaults
    private var equippedDecorationsCache: [String: [PetEquippedDecoration]] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        quantitiesByItemID = Self.decodeQuantities(
            defaults.data(forKey: Self.quantitiesKey)
        )
        equippedDecorationsBySlot = Self.decodeEquippedDecorations(
            defaults.data(forKey: Self.equippedDecorationsKey)
        )
    }

    func quantity(of itemID: String) -> Int {
        max(0, quantitiesByItemID[itemID, default: 0])
    }

    func ownedItems(
        in section: PetShopSection,
        decorationCategory: PetDecorationCategory? = nil
    ) -> [PetShopItemDefinition] {
        ShopCatalog.petMenuItems(
            in: section,
            decorationCategory: decorationCategory
        )
        .filter { quantity(of: $0.id) > 0 }
    }

    func equippedDecoration(
        for petID: String,
        skinID: String,
        category: PetDecorationCategory
    ) -> PetEquippedDecoration? {
        equippedDecorationsBySlot[
            PetEquippedDecoration.slotID(
                petID: petID,
                skinID: skinID,
                category: category
            )
        ]
    }

    func equippedDecorations(for petID: String, skinID: String) -> [PetEquippedDecoration] {
        let cacheKey = Self.petSkinCacheKey(petID: petID, skinID: skinID)
        if let cached = equippedDecorationsCache[cacheKey] {
            return cached
        }

        let decorations = PetDecorationCategory.allCases.compactMap {
            equippedDecoration(for: petID, skinID: skinID, category: $0)
        }
        equippedDecorationsCache[cacheKey] = decorations
        return decorations
    }

    /// Moves one decoration from the warehouse into the pet/skin category
    /// slot. Replacing a decoration returns the previous item to the warehouse.
    @discardableResult
    func equipDecoration(
        _ item: PetShopItemDefinition,
        for petID: String,
        skinID: String,
        position: PetDecorationPosition
    ) -> PetEquippedDecoration? {
        guard
            item.section == .decoration,
            let category = item.decorationCategory,
            quantity(of: item.id) > 0
        else { return nil }

        let slotID = PetEquippedDecoration.slotID(
            petID: petID,
            skinID: skinID,
            category: category
        )
        if let previous = equippedDecorationsBySlot[slotID] {
            quantitiesByItemID[previous.itemID, default: 0] += 1
        }
        guard removeOneWithoutPersisting(itemID: item.id) else { return nil }

        let decoration = PetEquippedDecoration(
            petID: petID,
            skinID: skinID,
            category: category,
            itemID: item.id,
            position: position
        )
        equippedDecorationsBySlot[slotID] = decoration
        invalidateEquippedDecorationsCache(petID: petID, skinID: skinID)
        persist()
        return decoration
    }

    @discardableResult
    func moveEquippedDecoration(
        for petID: String,
        skinID: String,
        category: PetDecorationCategory,
        to position: PetDecorationPosition
    ) -> Bool {
        let slotID = PetEquippedDecoration.slotID(
            petID: petID,
            skinID: skinID,
            category: category
        )
        guard var decoration = equippedDecorationsBySlot[slotID] else { return false }

        decoration.position = position
        equippedDecorationsBySlot[slotID] = decoration
        invalidateEquippedDecorationsCache(petID: petID, skinID: skinID)
        persist()
        return true
    }

    @discardableResult
    func resizeEquippedDecoration(
        for petID: String,
        skinID: String,
        category: PetDecorationCategory,
        by scaleChange: Double
    ) -> Bool {
        guard scaleChange.isFinite, scaleChange != 0 else { return false }

        let slotID = PetEquippedDecoration.slotID(
            petID: petID,
            skinID: skinID,
            category: category
        )
        guard var decoration = equippedDecorationsBySlot[slotID] else { return false }

        let resizedScale = PetEquippedDecoration.clampedScale(
            decoration.scale + scaleChange
        )
        guard resizedScale != decoration.scale else { return false }

        decoration.scale = resizedScale
        equippedDecorationsBySlot[slotID] = decoration
        invalidateEquippedDecorationsCache(petID: petID, skinID: skinID)
        persist()
        return true
    }

    /// Removes a decoration from the pet and returns it to the warehouse.
    @discardableResult
    func unequipDecoration(
        for petID: String,
        skinID: String,
        category: PetDecorationCategory
    ) -> Bool {
        let slotID = PetEquippedDecoration.slotID(
            petID: petID,
            skinID: skinID,
            category: category
        )
        guard let decoration = equippedDecorationsBySlot.removeValue(forKey: slotID) else {
            return false
        }

        quantitiesByItemID[decoration.itemID, default: 0] += 1
        invalidateEquippedDecorationsCache(petID: petID, skinID: skinID)
        persist()
        return true
    }

    /// The single purchasing interface for the pet-menu shop. A successful
    /// purchase always spends the coins and deposits one item in the warehouse.
    @discardableResult
    func purchase(
        _ item: PetShopItemDefinition,
        using progressStore: PetProgressStore
    ) -> Bool {
        guard progressStore.purchasePetMenuItem(item) else { return false }

        quantitiesByItemID[item.id, default: 0] += 1
        persist()
        return true
    }

    /// Uses one warehouse food directly. This path never creates a desktop
    /// food file; it deducts inventory and applies the pet rewards in-app.
    @discardableResult
    func useFood(
        _ item: PetShopItemDefinition,
        for petID: String,
        allowUnownedPet: Bool = false,
        progressStore: PetProgressStore,
        hungerStore: PetHungerStore
    ) -> PetInventoryFoodUseResult? {
        guard
            item.section == .food,
            let food = ShopCatalog.food(id: item.id),
            quantity(of: item.id) > 0,
            progressStore.canReceiveInventoryFood(
                for: petID,
                allowUnownedPet: allowUnownedPet
            )
        else { return nil }

        guard consumeOne(itemID: item.id) else { return nil }
        guard let experience = progressStore.receiveInventoryFood(
            food,
            for: petID,
            allowUnownedPet: allowUnownedPet
        ) else { return nil }

        return PetInventoryFoodUseResult(
            experience: experience,
            satiety: hungerStore.feed(food)
        )
    }

    @discardableResult
    func consumeOne(itemID: String) -> Bool {
        guard removeOneWithoutPersisting(itemID: itemID) else { return false }
        persist()
        return true
    }

    private func removeOneWithoutPersisting(itemID: String) -> Bool {
        let currentQuantity = quantity(of: itemID)
        guard currentQuantity > 0 else { return false }

        if currentQuantity == 1 {
            quantitiesByItemID.removeValue(forKey: itemID)
        } else {
            quantitiesByItemID[itemID] = currentQuantity - 1
        }
        return true
    }

    private func persist() {
        defaults.set(
            try? JSONEncoder().encode(quantitiesByItemID),
            forKey: Self.quantitiesKey
        )
        defaults.set(
            try? JSONEncoder().encode(equippedDecorationsBySlot),
            forKey: Self.equippedDecorationsKey
        )
    }

    private func invalidateEquippedDecorationsCache(petID: String, skinID: String) {
        equippedDecorationsCache.removeValue(
            forKey: Self.petSkinCacheKey(petID: petID, skinID: skinID)
        )
    }

    private static func petSkinCacheKey(petID: String, skinID: String) -> String {
        "\(petID)::\(skinID)"
    }

    private static func decodeQuantities(_ data: Data?) -> [String: Int] {
        guard
            let data,
            let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return [:] }

        return decoded.filter { $0.value > 0 }
    }

    private static func decodeEquippedDecorations(
        _ data: Data?
    ) -> [String: PetEquippedDecoration] {
        guard
            let data,
            let decoded = try? JSONDecoder().decode(
                [String: PetEquippedDecoration].self,
                from: data
            )
        else { return [:] }

        return decoded.filter { _, decoration in
            guard
                let item = ShopCatalog.petMenuItem(id: decoration.itemID),
                item.section == .decoration
            else { return false }
            return item.decorationCategory == decoration.category
        }
    }
}
