import XCTest
@testable import MacBookPet

final class MyPetsPlacementPlannerTests: XCTestCase {
    func testPlacementsContainEachPetSkinOnceAndUseDistinctSlots() {
        let placements = MyPetsPlacementPlanner.makePlacements(
            petSkins: [
                MyPetSkin(petID: "cube", skinID: "cube.classic"),
                MyPetSkin(petID: "cat", skinID: "cat.classic"),
                MyPetSkin(petID: "cube", skinID: "cube.classic"),
                MyPetSkin(petID: "cat", skinID: "cat.yellow"),
                MyPetSkin(petID: "dog", skinID: "dog.shiba")
            ],
            slotOrder: [3, 1, 0, 2]
        )

        XCTAssertEqual(
            placements.map(\.id),
            ["cube::cube.classic", "cat::cat.classic", "cat::cat.yellow", "dog::dog.shiba"]
        )
        XCTAssertEqual(Set(placements.map(\.slotIndex)).count, placements.count)
        XCTAssertTrue(placements.allSatisfy { (0...1).contains($0.xFraction) })
        XCTAssertTrue(placements.allSatisfy { (0...1).contains($0.yFraction) })
    }

    func testEmptyPetListProducesNoPlacements() {
        XCTAssertTrue(MyPetsPlacementPlanner.makePlacements(petSkins: []).isEmpty)
    }

    func testOwnedPetSkinsIncludesEveryOwnedSkinForOwnedPets() {
        let petSkins = MyPetsCatalog.ownedPetSkins(
            ownedPetIDs: [PetCatalog.cube.id, PetCatalog.cat.id],
            ownedSkinIDs: [
                "cube.classic",
                "cube.ice",
                "cat.classic",
                "cat.yellow",
                "dog.shiba"
            ]
        )

        XCTAssertEqual(
            petSkins.map(\.id),
            [
                "cube::cube.classic",
                "cube::cube.ice",
                "cat::cat.classic",
                "cat::cat.yellow"
            ]
        )
    }
}
