import XCTest
@testable import MacBookPet

final class PetInventoryStoreTests: XCTestCase {
    func testPetMenuCatalogHasRequestedFoodAndDecorationCategories() {
        XCTAssertEqual(
            PetDecorationCategory.allCases.map(\.title),
            ["头部", "颈部", "挂饰", "其他"]
        )
        XCTAssertEqual(
            ShopCatalog.petMenuItems(in: .food).map(\.name),
            ["小饼干", "能量棒", "宠物可乐", "鱼形烧饼", "布丁杯", "三色团子"]
        )
        XCTAssertEqual(
            ShopCatalog.petMenuItems(in: .food).map(\.price),
            [5, 10, 20, 8, 12, 15]
        )
        XCTAssertEqual(
            ShopCatalog.petMenuItems(in: .decoration, decorationCategory: .head).map(\.name),
            ["红色爪印棒球帽", "飞行员护目镜帽", "金黄叶子报童帽"]
        )
        XCTAssertTrue(
            ShopCatalog.petMenuItems(in: .decoration, decorationCategory: .head)
                .allSatisfy { $0.price == 30 }
        )
        XCTAssertEqual(
            ShopCatalog.petMenuItems(in: .decoration, decorationCategory: .neck).map(\.name),
            [
                "围巾",
                "蘑菇围巾",
                "格纹花朵围巾",
                "蓝条纹围巾",
                "奶油花朵围巾",
                "星愿流苏围巾",
                "红白条纹围巾",
                "红棕针织围巾",
                "彩色波点围巾",
                "锦鲤海浪围巾",
                "闪电摇滚围巾",
                "柠檬花边围巾",
                "星空围巾",
                "彩虹毛球围巾",
                "秋日格纹围巾",
                "松果菱格围巾",
                "草莓爱心围巾"
            ]
        )
        XCTAssertTrue(
            ShopCatalog.petMenuItems(in: .decoration, decorationCategory: .neck)
                .allSatisfy { $0.price == 30 }
        )
        XCTAssertEqual(PetShopSection.allCases.map(\.title), ["装饰", "食物", "宠物"])
        XCTAssertEqual(PetCatalog.pets.count, 5)
        XCTAssertEqual(PetCatalog.pets.flatMap(\.skins).count, 19)
    }

    @MainActor
    func testHeadDecorationPurchaseDepositsInMatchingWarehouseCategory() throws {
        let suiteName = "MacBookPetTests.HeadDecoration.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(40, forKey: "MacBookPet.coinBalance")

        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let cap = try XCTUnwrap(
            ShopCatalog.petMenuItem(id: "decoration.head.pawBaseballCap")
        )

        XCTAssertTrue(inventoryStore.purchase(cap, using: progressStore))
        XCTAssertEqual(progressStore.coins, 10)
        XCTAssertEqual(inventoryStore.quantity(of: cap.id), 1)
        XCTAssertEqual(
            inventoryStore.ownedItems(in: .decoration, decorationCategory: .head).map(\.id),
            [cap.id]
        )

        let reloadedInventory = PetInventoryStore(defaults: defaults)
        XCTAssertEqual(
            reloadedInventory.ownedItems(in: .decoration, decorationCategory: .head).map(\.id),
            [cap.id]
        )
    }

    @MainActor
    func testNeckDecorationPurchaseDepositsInMatchingWarehouseCategory() throws {
        let suiteName = "MacBookPetTests.NeckDecoration.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(40, forKey: "MacBookPet.coinBalance")

        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let scarf = try XCTUnwrap(
            ShopCatalog.petMenuItem(id: "decoration.neck.strawberryHeartScarf")
        )

        XCTAssertTrue(inventoryStore.purchase(scarf, using: progressStore))
        XCTAssertEqual(progressStore.coins, 10)
        XCTAssertEqual(inventoryStore.quantity(of: scarf.id), 1)
        XCTAssertEqual(
            inventoryStore.ownedItems(in: .decoration, decorationCategory: .neck).map(\.id),
            [scarf.id]
        )

        let reloadedInventory = PetInventoryStore(defaults: defaults)
        XCTAssertEqual(
            reloadedInventory.ownedItems(in: .decoration, decorationCategory: .neck).map(\.id),
            [scarf.id]
        )
    }

    func testDecorationPositionClampsAndMapsBetweenSizes() {
        let position = PetDecorationPosition(xFraction: -0.25, yFraction: 1.4)

        XCTAssertEqual(position, PetDecorationPosition(xFraction: 0, yFraction: 1))
        XCTAssertEqual(position.point(in: CGSize(width: 230, height: 230)), CGPoint(x: 0, y: 230))
    }

    func testDecorationRenderingSizeUsesDesktopPetBodyCanvas() {
        XCTAssertEqual(
            PetDecorationRenderingMetrics.sideLength(decorationScale: 1),
            PetMetrics.bodyContentSize * PetDecorationRenderingMetrics.relativeWidth,
            accuracy: 0.0001
        )
        XCTAssertNotEqual(
            PetDecorationRenderingMetrics.sideLength(decorationScale: 1),
            230 * PetDecorationRenderingMetrics.relativeWidth
        )
    }

    func testDressUpPreviewGeometryRoundTripsDesktopBodyPosition() {
        let geometry = PetDressUpPreviewGeometry(
            previewSize: CGSize(width: 230, height: 230),
            artworkScale: 2.3,
            petBaseScale: 1.15
        )
        let desktopBodyPoint = CGPoint(x: 31.5, y: 38.25)
        let previewPoint = geometry.previewPoint(forBodyPoint: desktopBodyPoint)
        let roundTrippedPoint = geometry.bodyPoint(forPreviewPoint: previewPoint)

        XCTAssertEqual(roundTrippedPoint.x, desktopBodyPoint.x, accuracy: 0.0001)
        XCTAssertEqual(roundTrippedPoint.y, desktopBodyPoint.y, accuracy: 0.0001)
    }

    @MainActor
    func testEquippingDecorationMovesItBetweenWarehousePetAndPersistence() throws {
        let suiteName = "MacBookPetTests.EquippedDecoration.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(100, forKey: "MacBookPet.coinBalance")

        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cat.id,
            selectedSkinID: PetCatalog.cat.skins[0].id,
            defaults: defaults
        )
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let scarf = try XCTUnwrap(ShopCatalog.petMenuItem(id: "decoration.neck.scarf"))
        let mushroom = try XCTUnwrap(
            ShopCatalog.petMenuItem(id: "decoration.neck.mushroomScarf")
        )
        XCTAssertTrue(inventoryStore.purchase(scarf, using: progressStore))
        XCTAssertTrue(inventoryStore.purchase(mushroom, using: progressStore))

        let firstPosition = PetDecorationPosition(xFraction: 0.35, yFraction: 0.42)
        XCTAssertNotNil(
            inventoryStore.equipDecoration(
                scarf,
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                position: firstPosition
            )
        )
        XCTAssertEqual(inventoryStore.quantity(of: scarf.id), 0)
        XCTAssertEqual(
            inventoryStore.equippedDecoration(
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                category: .neck
            )?.position,
            firstPosition
        )

        let movedPosition = PetDecorationPosition(xFraction: 0.6, yFraction: 0.55)
        XCTAssertTrue(
            inventoryStore.moveEquippedDecoration(
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                category: .neck,
                to: movedPosition
            )
        )

        XCTAssertTrue(
            inventoryStore.resizeEquippedDecoration(
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                category: .neck,
                by: 0.45
            )
        )
        let resizedInventory = PetInventoryStore(defaults: defaults)
        XCTAssertEqual(
            try XCTUnwrap(
                resizedInventory.equippedDecoration(
                    for: PetCatalog.cat.id,
                    skinID: "cat.classic",
                    category: .neck
                )
            ).scale,
            1.45,
            accuracy: 0.0001
        )

        let replacementPosition = PetDecorationPosition(xFraction: 0.5, yFraction: 0.7)
        XCTAssertNotNil(
            inventoryStore.equipDecoration(
                mushroom,
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                position: replacementPosition
            )
        )
        XCTAssertEqual(inventoryStore.quantity(of: scarf.id), 1)
        XCTAssertEqual(inventoryStore.quantity(of: mushroom.id), 0)

        let reloadedInventory = PetInventoryStore(defaults: defaults)
        let reloadedDecoration = try XCTUnwrap(
            reloadedInventory.equippedDecoration(
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                category: .neck
            )
        )
        XCTAssertEqual(reloadedDecoration.itemID, mushroom.id)
        XCTAssertEqual(reloadedDecoration.position, replacementPosition)
        XCTAssertEqual(reloadedDecoration.scale, 1)

        XCTAssertTrue(
            reloadedInventory.unequipDecoration(
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                category: .neck
            )
        )
        XCTAssertEqual(reloadedInventory.quantity(of: mushroom.id), 1)
        XCTAssertNil(
            reloadedInventory.equippedDecoration(
                for: PetCatalog.cat.id,
                skinID: "cat.classic",
                category: .neck
            )
        )
    }

    func testEquippedDecorationDecodesLegacyRecordWithoutScale() throws {
        let legacyJSON = """
        {
          "petID": "cat",
          "skinID": "cat.classic",
          "category": "neck",
          "itemID": "decoration.neck.scarf",
          "position": { "xFraction": 0.5, "yFraction": 0.6 }
        }
        """.data(using: .utf8)!

        let decoration = try JSONDecoder().decode(
            PetEquippedDecoration.self,
            from: legacyJSON
        )

        XCTAssertEqual(decoration.scale, 1)
    }

    @MainActor
    func testPurchaseDepositsItemAndPersistsWarehouseQuantity() throws {
        let suiteName = "MacBookPetTests.PetInventoryStore.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(100, forKey: "MacBookPet.coinBalance")

        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let cookie = try XCTUnwrap(ShopCatalog.petMenuItem(id: "food.smallCookie"))

        XCTAssertTrue(inventoryStore.purchase(cookie, using: progressStore))
        XCTAssertEqual(progressStore.coins, 95)
        XCTAssertEqual(inventoryStore.quantity(of: cookie.id), 1)

        let reloadedInventory = PetInventoryStore(defaults: defaults)
        XCTAssertEqual(reloadedInventory.quantity(of: cookie.id), 1)
        XCTAssertEqual(reloadedInventory.ownedItems(in: .food).map(\.id), [cookie.id])
    }

    @MainActor
    func testPurchaseFailsWithoutCoinsAndDoesNotAddInventory() throws {
        let suiteName = "MacBookPetTests.PetInventoryStore.NoCoins.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let cookie = try XCTUnwrap(ShopCatalog.petMenuItem(id: "food.smallCookie"))

        XCTAssertFalse(inventoryStore.purchase(cookie, using: progressStore))
        XCTAssertEqual(inventoryStore.quantity(of: cookie.id), 0)
    }

    @MainActor
    func testPaidPetPurchaseUnlocksPetAndItsFirstSkin() throws {
        let suiteName = "MacBookPetTests.PetStore.Pet.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(300, forKey: "MacBookPet.coinBalance")

        let store = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )

        XCTAssertFalse(store.ownsPet(PetCatalog.frog.id))
        XCTAssertTrue(store.canBuyPet(PetCatalog.frog))
        XCTAssertTrue(store.buyPet(PetCatalog.frog))
        XCTAssertTrue(store.ownsPet(PetCatalog.frog.id))
        XCTAssertTrue(store.ownsSkin(PetCatalog.frog.skins[0].id))
        XCTAssertEqual(store.coins, 50)

        let reloadedStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        XCTAssertTrue(reloadedStore.ownsPet(PetCatalog.frog.id))
        XCTAssertTrue(reloadedStore.ownsSkin(PetCatalog.frog.skins[0].id))
    }

    @MainActor
    func testPaidSkinPurchaseUnlocksSkin() throws {
        let suiteName = "MacBookPetTests.PetStore.Skin.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(40, forKey: "MacBookPet.coinBalance")

        let store = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cat.id,
            selectedSkinID: PetCatalog.cat.skins[0].id,
            defaults: defaults
        )
        let skin = try XCTUnwrap(PetCatalog.cat.skin(id: "cat.grayTabby"))

        XCTAssertFalse(store.ownsSkin(skin.id))
        XCTAssertTrue(store.canBuySkin(skin, for: PetCatalog.cat.id))
        XCTAssertTrue(store.buySkin(skin, for: PetCatalog.cat.id))
        XCTAssertTrue(store.ownsSkin(skin.id))
        XCTAssertEqual(store.coins, 10)

        let reloadedStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cat.id,
            selectedSkinID: PetCatalog.cat.skins[0].id,
            defaults: defaults
        )
        XCTAssertTrue(reloadedStore.ownsSkin(skin.id))
    }

    @MainActor
    func testWarehouseFoodUseConsumesOneAndAppliesRewardsWithoutDesktopFile() throws {
        let suiteName = "MacBookPetTests.InventoryFoodUse.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let now = Date()
        defaults.set(100, forKey: "MacBookPet.coinBalance")
        defaults.set(40, forKey: "MacBookPet.petSatiety")
        defaults.set(now, forKey: "MacBookPet.petSatietyLastUpdated")

        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        let hungerStore = PetHungerStore(defaults: defaults, now: now)
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let cookie = try XCTUnwrap(ShopCatalog.petMenuItem(id: "food.smallCookie"))
        XCTAssertTrue(inventoryStore.purchase(cookie, using: progressStore))

        let result = try XCTUnwrap(
            inventoryStore.useFood(
                cookie,
                for: PetCatalog.cube.id,
                progressStore: progressStore,
                hungerStore: hungerStore
            )
        )

        XCTAssertEqual(result, PetInventoryFoodUseResult(experience: 8, satiety: 18))
        XCTAssertEqual(inventoryStore.quantity(of: cookie.id), 0)
        XCTAssertEqual(progressStore.experienceProgress(for: PetCatalog.cube.id), 8)
        XCTAssertEqual(hungerStore.satiety, 58)

        let reloadedInventory = PetInventoryStore(defaults: defaults)
        let reloadedProgress = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )
        let reloadedHunger = PetHungerStore(defaults: defaults, now: now)
        XCTAssertEqual(reloadedInventory.quantity(of: cookie.id), 0)
        XCTAssertEqual(reloadedProgress.experienceProgress(for: PetCatalog.cube.id), 8)
        XCTAssertEqual(reloadedHunger.satiety, 58)
    }
}
