import Combine
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import MacBookPet

final class PetPerformanceOptimizationTests: XCTestCase {
    func testListThumbnailDownsamplesWithoutFullSizeDecodeAndCanBeReleased() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PetListThumbnail-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: 1_024,
                height: 512,
                bitsPerComponent: 8,
                bytesPerRow: 1_024 * 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        context.setFillColor(CGColor(red: 0.9, green: 0.4, blue: 0.2, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 1_024, height: 512))
        let sourceImage = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, sourceImage, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))

        PetListThumbnailCache.removeAll()
        let thumbnail = try XCTUnwrap(
            PetListThumbnailCache.thumbnail(for: url, maxPixelSize: 128)
        )
        XCTAssertEqual(thumbnail.width, 128)
        XCTAssertEqual(thumbnail.height, 64)
        XCTAssertNotNil(
            PetListThumbnailCache.cachedThumbnail(for: url, maxPixelSize: 128)
        )

        PetListThumbnailCache.removeAll()
        XCTAssertNil(
            PetListThumbnailCache.cachedThumbnail(for: url, maxPixelSize: 128)
        )
    }

    func testClearedThumbnailGenerationCannotRepopulateReleasedPageCache() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("PetListThumbnailGeneration-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: url) }

        let context = try XCTUnwrap(
            CGContext(
                data: nil,
                width: 256,
                height: 256,
                bitsPerComponent: 8,
                bytesPerRow: 256 * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        )
        let sourceImage = try XCTUnwrap(context.makeImage())
        let destination = try XCTUnwrap(
            CGImageDestinationCreateWithURL(
                url as CFURL,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        )
        CGImageDestinationAddImage(destination, sourceImage, nil)
        XCTAssertTrue(CGImageDestinationFinalize(destination))

        PetListThumbnailCache.removeAll()
        let staleGeneration = PetListThumbnailCache.currentGeneration()
        PetListThumbnailCache.removeAll()
        XCTAssertNotNil(
            PetListThumbnailCache.thumbnail(
                for: url,
                maxPixelSize: 64,
                generation: staleGeneration
            )
        )
        XCTAssertNil(
            PetListThumbnailCache.cachedThumbnail(for: url, maxPixelSize: 64)
        )
    }

    func testPhysicsRefreshPolicyUsesRestingRateOnlyWhenPetIsIdleAndMouseIsFarAway() {
        XCTAssertEqual(
            PetPhysicsRefreshPolicy.mode(
                isResting: true,
                isDragging: false,
                mouseDistance: PetPhysicsRefreshPolicy.mouseWakeDistance + 1
            ),
            .resting
        )
        XCTAssertEqual(PetPhysicsRefreshMode.resting.interval, 0.2, accuracy: 0.0001)

        XCTAssertEqual(
            PetPhysicsRefreshPolicy.mode(
                isResting: false,
                isDragging: false,
                mouseDistance: 1_000
            ),
            .active
        )
        XCTAssertEqual(
            PetPhysicsRefreshPolicy.mode(
                isResting: true,
                isDragging: true,
                mouseDistance: 1_000
            ),
            .active
        )
        XCTAssertEqual(
            PetPhysicsRefreshPolicy.mode(
                isResting: true,
                isDragging: false,
                mouseDistance: PetPhysicsRefreshPolicy.mouseWakeDistance
            ),
            .active
        )
        XCTAssertEqual(PetPhysicsRefreshMode.active.interval, 1.0 / 60.0, accuracy: 0.0001)
    }

    @MainActor
    func testMotionTransformDoesNotPublishUnchangedOrSubToleranceValues() {
        let state = PetMotionState()
        var publishedUpdateCount = 0
        let cancellable = state.objectWillChange.sink {
            publishedUpdateCount += 1
        }

        XCTAssertFalse(
            state.updateMotionTransform(
                rotationDegrees: 0,
                stretchX: 1,
                stretchY: 1
            )
        )
        XCTAssertFalse(
            state.updateMotionTransform(
                rotationDegrees: 0.00005,
                stretchX: 1.00005,
                stretchY: 0.99995
            )
        )
        XCTAssertEqual(publishedUpdateCount, 0)

        XCTAssertTrue(
            state.updateMotionTransform(
                rotationDegrees: 3,
                stretchX: 1.08,
                stretchY: 0.96
            )
        )
        let countAfterChange = publishedUpdateCount
        XCTAssertGreaterThan(countAfterChange, 0)

        XCTAssertFalse(
            state.updateMotionTransform(
                rotationDegrees: 3,
                stretchX: 1.08,
                stretchY: 0.96
            )
        )
        XCTAssertEqual(publishedUpdateCount, countAfterChange)
        withExtendedLifetime(cancellable) {}
    }

    @MainActor
    func testCurrentVisualConfigurationCacheRefreshesAfterOverrideChanges() throws {
        let rootURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("PetVisualConfigurationCache-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: rootURL) }

        let store = PetCustomizationStore(customRootURL: rootURL)
        let petID = PetCatalog.cube.id
        let skinID = "cube.classic"

        let initial = store.resolvedVisualConfiguration(petID: petID, skinID: skinID)
        XCTAssertTrue(initial.resolvedGravityEnabled)
        XCTAssertEqual(
            store.resolvedVisualConfiguration(petID: petID, skinID: skinID),
            initial
        )

        var override = initial
        override.setGravityEnabled(false)
        try store.saveVisualOverride(override, petID: petID, skinID: skinID)
        XCTAssertFalse(
            store.resolvedVisualConfiguration(petID: petID, skinID: skinID)
                .resolvedGravityEnabled
        )

        try store.resetVisualOverride(petID: petID, skinID: skinID)
        XCTAssertTrue(
            store.resolvedVisualConfiguration(petID: petID, skinID: skinID)
                .resolvedGravityEnabled
        )
    }

    @MainActor
    func testEquippedDecorationCacheInvalidatesAfterEveryMutation() throws {
        let suiteName = "MacBookPetTests.EquippedDecorationCache.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(100, forKey: "MacBookPet.coinBalance")

        let petID = PetCatalog.cat.id
        let skinID = "cat.classic"
        let progressStore = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: petID,
            selectedSkinID: skinID,
            defaults: defaults
        )
        let inventoryStore = PetInventoryStore(defaults: defaults)
        let scarf = try XCTUnwrap(ShopCatalog.petMenuItem(id: "decoration.neck.scarf"))
        XCTAssertTrue(inventoryStore.purchase(scarf, using: progressStore))

        XCTAssertEqual(inventoryStore.equippedDecorations(for: petID, skinID: skinID), [])

        let initialPosition = PetDecorationPosition(xFraction: 0.4, yFraction: 0.5)
        XCTAssertNotNil(
            inventoryStore.equipDecoration(
                scarf,
                for: petID,
                skinID: skinID,
                position: initialPosition
            )
        )
        XCTAssertEqual(
            inventoryStore.equippedDecorations(for: petID, skinID: skinID).first?.position,
            initialPosition
        )

        let movedPosition = PetDecorationPosition(xFraction: 0.65, yFraction: 0.7)
        XCTAssertTrue(
            inventoryStore.moveEquippedDecoration(
                for: petID,
                skinID: skinID,
                category: .neck,
                to: movedPosition
            )
        )
        XCTAssertEqual(
            inventoryStore.equippedDecorations(for: petID, skinID: skinID).first?.position,
            movedPosition
        )

        XCTAssertTrue(
            inventoryStore.resizeEquippedDecoration(
                for: petID,
                skinID: skinID,
                category: .neck,
                by: 0.25
            )
        )
        XCTAssertEqual(
            try XCTUnwrap(
                inventoryStore.equippedDecorations(for: petID, skinID: skinID).first
            ).scale,
            1.25,
            accuracy: 0.0001
        )

        XCTAssertTrue(
            inventoryStore.unequipDecoration(
                for: petID,
                skinID: skinID,
                category: .neck
            )
        )
        XCTAssertEqual(inventoryStore.equippedDecorations(for: petID, skinID: skinID), [])
    }
}
