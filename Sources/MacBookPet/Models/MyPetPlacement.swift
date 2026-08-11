import CoreGraphics

struct MyPetSkin: Identifiable, Equatable, Hashable {
    let petID: String
    let skinID: String

    var id: String { "\(petID)::\(skinID)" }
}

struct MyPetPlacement: Identifiable, Equatable {
    let petID: String
    let skinID: String
    let slotIndex: Int
    let xFraction: CGFloat
    let yFraction: CGFloat

    var id: String { "\(petID)::\(skinID)" }
}

enum MyPetsPlacementPlanner {
    static func makePlacements(
        petSkins: [MyPetSkin],
        slotOrder: [Int]? = nil
    ) -> [MyPetPlacement] {
        var seenIDs = Set<String>()
        let uniquePetSkins = petSkins.filter { seenIDs.insert($0.id).inserted }
        guard !uniquePetSkins.isEmpty else { return [] }

        let columns = Int(ceil(sqrt(Double(uniquePetSkins.count))))
        let rows = Int(ceil(Double(uniquePetSkins.count) / Double(columns)))
        let slotCount = columns * rows
        let orderedSlots = resolvedSlotOrder(slotOrder, slotCount: slotCount)

        return zip(uniquePetSkins, orderedSlots).map { petSkin, slotIndex in
            let column = slotIndex % columns
            let row = slotIndex / columns
            return MyPetPlacement(
                petID: petSkin.petID,
                skinID: petSkin.skinID,
                slotIndex: slotIndex,
                xFraction: (CGFloat(column) + 0.5) / CGFloat(columns),
                yFraction: (CGFloat(row) + 0.5) / CGFloat(rows)
            )
        }
    }

    private static func resolvedSlotOrder(_ requestedOrder: [Int]?, slotCount: Int) -> [Int] {
        guard let requestedOrder else {
            return Array(0..<slotCount).shuffled()
        }

        var seenSlots = Set<Int>()
        let validRequestedSlots = requestedOrder.filter {
            (0..<slotCount).contains($0) && seenSlots.insert($0).inserted
        }
        let remainingSlots = (0..<slotCount).filter { seenSlots.insert($0).inserted }
        return validRequestedSlots + remainingSlots
    }
}

enum MyPetsCatalog {
    static func ownedPetSkins(
        ownedPetIDs: Set<String>,
        ownedSkinIDs: Set<String>
    ) -> [MyPetSkin] {
        PetCatalog.pets.flatMap { pet in
            guard ownedPetIDs.contains(pet.id) else { return [MyPetSkin]() }
            return pet.skins.compactMap { skin in
                guard ownedSkinIDs.contains(skin.id) else { return nil }
                return MyPetSkin(petID: pet.id, skinID: skin.id)
            }
        }
    }
}
