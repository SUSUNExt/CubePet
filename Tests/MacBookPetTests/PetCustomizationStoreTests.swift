import Foundation
import XCTest
@testable import MacBookPet

final class PetCustomizationStoreTests: XCTestCase {
    func testCubeSpecialSkinsAreAvailableForImmediatePreview() {
        let ice = PetCatalog.cube.skin(id: "cube.ice")
        let rainbow = PetCatalog.cube.skin(id: "cube.rainbow")
        let ice2 = PetCatalog.cube.skin(id: "cube.ice2")
        let rainbow2 = PetCatalog.cube.skin(id: "cube.rainbow2")

        XCTAssertEqual(ice?.unlockLevel, 1)
        XCTAssertEqual(ice?.price, 0)
        XCTAssertEqual(rainbow?.unlockLevel, 1)
        XCTAssertEqual(rainbow?.price, 0)
        XCTAssertEqual(ice2?.unlockLevel, 1)
        XCTAssertEqual(ice2?.price, 0)
        XCTAssertEqual(rainbow2?.unlockLevel, 1)
        XCTAssertEqual(rainbow2?.price, 0)
        XCTAssertEqual(CubeSkinStyle(skinID: "cube.ice"), .ice)
        XCTAssertEqual(CubeSkinStyle(skinID: "cube.rainbow"), .rainbow)
        XCTAssertEqual(CubeSkinStyle(skinID: "cube.ice2"), .ice2)
        XCTAssertEqual(CubeSkinStyle(skinID: "cube.rainbow2"), .rainbow2)
    }

    func testLittleCookieUsesTheExtractedBlackBeanEyeModule() {
        XCTAssertEqual(PetCatalog.cookie.name, .cookie)
        XCTAssertEqual(PetCatalog.cookie.skins.map(\.name), [.cookieClassic])

        let configuration = PetVisualDefaults.configuration(
            petID: PetCatalog.cookie.id,
            skinID: "cookie.classic"
        )
        let normal = configuration.configuration(for: .normal)

        XCTAssertEqual(normal.base, .bundledAsset(name: "CookiePetFaceless"))
        XCTAssertEqual(normal.eyes?.kind, .cookieBlackBean)
        XCTAssertEqual(normal.eyes?.center, NormalizedVisualPoint(x: 0.5, y: 0.44))
        XCTAssertEqual(normal.eyes?.resolvedPupilScale, 0.5)
        XCTAssertEqual(normal.eyes?.resolvedPupilGazeScale, 0.27377158717105265)
        XCTAssertEqual(normal.eyes?.spacing, -1.22080592105263)
        XCTAssertTrue(normal.eyes?.followsMouse(for: .calm) ?? false)
        XCTAssertTrue(normal.eyes?.usesSingleColorEyeControls ?? false)
    }

    func testLittleCookieOfficialDefaultsMatchSavedStateLayouts() {
        let configuration = PetVisualDefaults.configuration(
            petID: PetCatalog.cookie.id,
            skinID: "cookie.classic"
        )

        let happy = configuration.configuration(for: .happy).eyes
        XCTAssertEqual(happy?.kind, .happy)
        XCTAssertEqual(happy?.center, NormalizedVisualPoint(x: 0.5058791035353535, y: 0.41216303661616166))
        XCTAssertEqual(happy?.scale, 0.6333666424418604)
        XCTAssertEqual(happy?.spacing, 11.96278782894737)
        XCTAssertEqual(happy?.resolvedColorMode, .brown)

        let scared = configuration.configuration(for: .scared).eyes
        XCTAssertEqual(scared?.kind, .scared)
        XCTAssertEqual(scared?.spacing, 12.879607681888547)
        XCTAssertEqual(scared?.resolvedColorMode, .brown)

        let sleeping = configuration.configuration(for: .sleeping).eyes
        XCTAssertEqual(sleeping?.kind, .sleeping)
        XCTAssertEqual(sleeping?.center, NormalizedVisualPoint(x: 0.5098248106060606, y: 0.3701270517676768))
        XCTAssertEqual(sleeping?.scale, 0.6694222383720931)
        XCTAssertEqual(sleeping?.spacing, 8.169117647058826)
        XCTAssertEqual(sleeping?.resolvedColorMode, .brown)

        XCTAssertEqual(configuration.configuration(for: .eating).eyes?.kind, .happy)
        XCTAssertEqual(configuration.configuration(for: .eating).eyes?.spacing, 12.879607681888547)
        XCTAssertEqual(configuration.configuration(for: .hungry).eyes?.kind, .happy)
        XCTAssertEqual(configuration.configuration(for: .hungry).eyes?.spacing, 12.879607681888547)
    }

    @MainActor
    func testLegacyCookieBlackBeanSettingsRestoreVisibleMouseFollowing() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        var legacyConfiguration = PetVisualDefaults.cookie
        var normal = legacyConfiguration.configuration(for: .normal)
        normal.eyes?.outerEyeScale = 0.8
        normal.eyes?.pupilSpacing = -1
        normal.eyes?.pupilGazeScale = 0.02
        legacyConfiguration.setConfiguration(normal, for: .normal)

        let configurationData = try JSONEncoder().encode(legacyConfiguration)
        let configurationObject = try JSONSerialization.jsonObject(with: configurationData)
        let document: [String: Any] = [
            "schemaVersion": 3,
            "visualOverrides": ["cookie::cookie.classic": configurationObject],
            "customPets": [],
            "eyePresets": [],
            "musicReactionSettings": [
                "isEnabled": true,
                "isSwayingEnabled": true,
                "areMusicNotesEnabled": true
            ]
        ]
        let documentData = try JSONSerialization.data(withJSONObject: document)
        try fileManager.createDirectory(at: temporaryRoot, withIntermediateDirectories: true)
        try documentData.write(to: temporaryRoot.appendingPathComponent("customization.json"))

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let eyes = try XCTUnwrap(
            store.visualConfiguration(
                petID: PetCatalog.cookie.id,
                skinID: "cookie.classic",
                official: PetVisualDefaults.cookie
            ).configuration(for: .normal).eyes
        )

        XCTAssertEqual(eyes.resolvedPupilGazeScale, 1)
        XCTAssertNil(eyes.outerEyeScale)
        XCTAssertNil(eyes.pupilSpacing)
    }

    @MainActor
    func testLittleCookieEyeChoicesPersistIndependentlyForEachState() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        var override = PetVisualDefaults.cookie
        var normal = override.configuration(for: .normal)
        normal.eyes?.kind = .catDefault
        override.setConfiguration(normal, for: .normal)

        var happy = override.configuration(for: .happy)
        happy.eyes?.kind = .happy
        override.setConfiguration(happy, for: .happy)

        var scared = override.configuration(for: .scared)
        scared.eyes?.kind = .scared
        override.setConfiguration(scared, for: .scared)
        try store.saveVisualOverride(
            override,
            petID: PetCatalog.cookie.id,
            skinID: "cookie.classic"
        )

        let resolved = store.visualConfiguration(
            petID: PetCatalog.cookie.id,
            skinID: "cookie.classic",
            official: PetVisualDefaults.cookie
        )
        XCTAssertEqual(resolved.configuration(for: .normal).eyes?.kind, .catDefault)
        XCTAssertEqual(resolved.configuration(for: .happy).eyes?.kind, .happy)
        XCTAssertEqual(resolved.configuration(for: .scared).eyes?.kind, .scared)
        XCTAssertEqual(resolved.configuration(for: .eating).eyes?.kind, .happy)
        XCTAssertEqual(resolved.configuration(for: .hungry).eyes?.kind, .happy)
        XCTAssertEqual(resolved.configuration(for: .sleeping).eyes?.kind, .sleeping)
    }

    @MainActor
    func testLittleCookieSleepingEyesPersistIndependentlyFromAwakeEyes() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        var override = PetVisualDefaults.cookie
        var sleeping = override.configuration(for: .sleeping)
        sleeping.eyes = PetEyeModuleConfiguration(
            kind: .sleeping,
            center: NormalizedVisualPoint(x: 0.42, y: 0.37),
            spacing: 3
        )
        override.setConfiguration(sleeping, for: .sleeping)
        try store.saveVisualOverride(
            override,
            petID: PetCatalog.cookie.id,
            skinID: "cookie.classic"
        )

        let resolved = store.visualConfiguration(
            petID: PetCatalog.cookie.id,
            skinID: "cookie.classic",
            official: PetVisualDefaults.cookie
        )
        XCTAssertEqual(resolved.configuration(for: .normal).eyes?.kind, .cookieBlackBean)
        XCTAssertEqual(resolved.configuration(for: .sleeping).eyes?.kind, .sleeping)
        XCTAssertEqual(
            resolved.configuration(for: .sleeping).eyes?.center,
            NormalizedVisualPoint(x: 0.42, y: 0.37)
        )
    }

    @MainActor
    func testSystemMetricsMonitorStopsSamplingWhenStopped() {
        let monitor = SystemMetricsMonitor()
        XCTAssertFalse(monitor.isRunning)

        monitor.start()
        XCTAssertTrue(monitor.isRunning)

        monitor.stop()
        XCTAssertFalse(monitor.isRunning)
    }

    func testShortcutSettingsPersistOnlyRegisteredShortcut() {
        let suiteName = "MacBookPetTests.ShortcutSettings.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let settings = ShortcutSettings(defaults: defaults)
        XCTAssertEqual(settings.shortcut, .defaultShortcut)

        let registeredShortcut = KeyboardShortcutDefinition(
            keyCode: 1,
            carbonModifiers: 1 << 11,
            keyName: "S"
        )
        settings.saveRegisteredShortcut(registeredShortcut)

        XCTAssertEqual(settings.shortcut, registeredShortcut)
        XCTAssertEqual(
            ShortcutSettings(defaults: defaults).shortcut,
            registeredShortcut
        )
    }

    @MainActor
    func testPetContextMenuTextIsLocalized() {
        let settings = LanguageSettings()
        let originalLanguage = settings.language
        defer { settings.language = originalLanguage }

        let expectedText: [(AppLanguage, String, String)] = [
            (.english, "Buy Food", "Show Main Menu"),
            (.japanese, "食べ物を購入", "メインメニューを表示"),
            (.korean, "먹이 구매", "메인 메뉴 열기"),
            (.simplifiedChinese, "购买食物", "呼出菜单"),
            (.traditionalChinese, "購買食物", "呼出選單")
        ]

        for (language, buyFood, showMainMenu) in expectedText {
            settings.language = language
            XCTAssertEqual(settings.text(.buyFood), buyFood)
            XCTAssertEqual(settings.text(.showMainMenu), showMainMenu)
        }
    }

    @MainActor
    func testUpdateVersionComparisonRecognizesOnlyNewerStableReleases() {
        XCTAssertTrue(AppUpdateAvailability.isNewerRelease(tagName: "v0.9.8", than: "0.9.7"))
        XCTAssertTrue(AppUpdateAvailability.isNewerRelease(tagName: "0.10.0", than: "0.9.9"))
        XCTAssertFalse(AppUpdateAvailability.isNewerRelease(tagName: "v0.9.7", than: "0.9.7"))
        XCTAssertFalse(AppUpdateAvailability.isNewerRelease(tagName: "not-a-version", than: "0.9.7"))
    }

    @MainActor
    func testCustomPetAndImportedAssetPersistAcrossStoreReload() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        let assetID = try store.importPNG(from: fixturePNGURL)
        let visualConfiguration = PetVisualConfiguration(
            states: [
                .normal: PetStateVisualConfiguration(
                    base: .importedAsset(id: assetID),
                    eyes: PetEyeModuleConfiguration(kind: .tracking)
                )
            ],
            bottomPetEnabled: true,
            gravityEnabled: false
        )

        let pet = try store.createCustomPet(
            name: "  Test Pet  ",
            visualConfiguration: visualConfiguration
        )

        XCTAssertTrue(pet.id.hasPrefix("custom:"))
        XCTAssertEqual(pet.name, "Test Pet")
        XCTAssertNotNil(store.assetURL(for: assetID))

        let reloadedStore = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        XCTAssertEqual(reloadedStore.customPet(id: pet.id)?.name, "Test Pet")
        XCTAssertEqual(
            reloadedStore.customPet(id: pet.id)?.visualConfiguration,
            visualConfiguration
        )
        XCTAssertFalse(
            reloadedStore.customPet(id: pet.id)?.visualConfiguration.resolvedGravityEnabled ?? true
        )
    }

    func testLegacyVisualConfigurationDefaultsToGravityEnabled() {
        let configuration = PetVisualConfiguration(
            states: [
                .normal: PetStateVisualConfiguration(base: .officialSkin, eyes: nil)
            ]
        )

        XCTAssertTrue(configuration.resolvedGravityEnabled)
    }

    func testMusicReactionDefaultsToSwayingOn() {
        XCTAssertTrue(MusicReactionSettings().isSwayingEnabled)
    }

    func testSupportedThirdPartyMusicAppsAreRecognizedByBundleIdentifier() {
        XCTAssertTrue(
            MusicPlaybackMonitor.isSupportedThirdPartyMusicApp(
                bundleIdentifier: "com.netease.163music",
                displayName: nil
            )
        )
        XCTAssertFalse(
            MusicPlaybackMonitor.isSupportedThirdPartyMusicApp(
                bundleIdentifier: "com.apple.Music",
                displayName: "Music"
            )
        )
        for identifier in [
            "com.tencent.QQMusicMac",
            "com.kugou.kugou1002",
            "com.kugou.KugouMusic",
            "com.kugou.music"
        ] {
            XCTAssertTrue(
                MusicPlaybackMonitor.isSupportedThirdPartyMusicApp(
                    bundleIdentifier: identifier,
                    displayName: nil
                )
            )
        }
    }

    func testSupportedThirdPartyMusicAppsAreRecognizedByDisplayName() {
        for name in ["网易云音乐", "QQ音乐", "酷狗音乐"] {
            XCTAssertTrue(
                MusicPlaybackMonitor.isSupportedThirdPartyMusicApp(
                    bundleIdentifier: nil,
                    displayName: name
                )
            )
        }
    }

    func testMusicPlaybackQueryFailureEndsMusicReaction() {
        XCTAssertFalse(MusicPlaybackMonitor.resolvedPlaybackState([nil]))
        XCTAssertFalse(MusicPlaybackMonitor.resolvedPlaybackState([false, nil]))
        XCTAssertTrue(MusicPlaybackMonitor.resolvedPlaybackState([false, nil, true]))
    }

    func testListeningUsesTheHappyVisualExpression() {
        switch PetExpression.listening.visualRenderingExpression {
        case .happy:
            break
        default:
            XCTFail("Listening should render the same facial expression as happy.")
        }
    }

    @MainActor
    func testMusicReactionSettingsPersistAcrossStoreReload() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        try store.setMusicReactionEnabled(true)
        try store.setMusicSwayingEnabled(false)
        try store.setMusicNotesEnabled(false)

        let reloadedStore = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        XCTAssertEqual(
            reloadedStore.musicReactionSettings,
            MusicReactionSettings(
                isEnabled: true,
                isSwayingEnabled: false,
                areMusicNotesEnabled: false
            )
        )
    }

    @MainActor
    func testCustomPetCanBeUpdatedAndDeletedWithItsUnusedAsset() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        let assetID = try store.importPNG(from: fixturePNGURL)
        let visualConfiguration = PetVisualConfiguration(
            states: [
                .normal: PetStateVisualConfiguration(
                    base: .importedAsset(id: assetID),
                    eyes: nil
                )
            ]
        )
        let pet = try store.createCustomPet(
            name: "Original Name",
            visualConfiguration: visualConfiguration
        )

        try store.updateCustomPet(
            id: pet.id,
            name: "Updated Name",
            visualConfiguration: visualConfiguration
        )
        XCTAssertEqual(store.customPet(id: pet.id)?.name, "Updated Name")

        try store.deleteCustomPet(id: pet.id)
        XCTAssertNil(store.customPet(id: pet.id))
        XCTAssertNil(store.assetURL(for: assetID))

        let reloadedStore = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        XCTAssertTrue(reloadedStore.customPets.isEmpty)
    }

    @MainActor
    func testFrameAnimationAssetPersistsInFrameOrder() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        let assetID = try store.importVisualAsset(from: [fixturePNGURL, fixturePNGURL])
        let asset = try XCTUnwrap(store.importedVisualAsset(for: assetID))

        XCTAssertEqual(asset.kind, .frameAnimation)
        XCTAssertTrue(asset.isAnimated)
        XCTAssertEqual(asset.frameCount, 2)
        XCTAssertEqual(asset.frameURLs.map(\.lastPathComponent), ["0000.png", "0001.png"])

        let configuration = PetVisualConfiguration(
            states: [
                .normal: PetStateVisualConfiguration(
                    base: .importedAsset(id: assetID),
                    eyes: nil,
                    animationPlaybackRate: 1.5
                )
            ]
        )
        let pet = try store.createCustomPet(name: "Frame Pet", visualConfiguration: configuration)
        let reloadedStore = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)

        XCTAssertEqual(
            reloadedStore.customPet(id: pet.id)?.visualConfiguration.configuration(for: .normal).animationPlaybackRate,
            1.5
        )
        XCTAssertEqual(reloadedStore.importedVisualAsset(for: assetID)?.frameCount, 2)
    }

    @MainActor
    func testFrameAnimationCanBeReorderedAndReloaded() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let sourceDirectory = temporaryRoot.appendingPathComponent("sources", isDirectory: true)
        try fileManager.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        let sourceURLs = ["png", "jpg", "heic"].map {
            sourceDirectory.appendingPathComponent("frame.\($0)", isDirectory: false)
        }
        for sourceURL in sourceURLs {
            try fileManager.copyItem(at: fixturePNGURL, to: sourceURL)
        }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let assetID = try store.importVisualAsset(from: sourceURLs)
        XCTAssertEqual(
            store.importedVisualAsset(for: assetID)?.frameURLs.map(\.lastPathComponent),
            ["0000.png", "0001.jpg", "0002.heic"]
        )

        try store.reorderFrames(assetID: assetID, from: 2, to: 1)
        XCTAssertEqual(
            store.importedVisualAsset(for: assetID)?.frameURLs.map(\.lastPathComponent),
            ["0000.png", "0001.heic", "0002.jpg"]
        )

        _ = try store.createCustomPet(
            name: "Reordered Frame Pet",
            visualConfiguration: PetVisualConfiguration(
                states: [
                    .normal: PetStateVisualConfiguration(
                        base: .importedAsset(id: assetID),
                        eyes: nil
                    )
                ]
            )
        )

        let reloadedStore = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        XCTAssertEqual(
            reloadedStore.importedVisualAsset(for: assetID)?.frameURLs.map(\.lastPathComponent),
            ["0000.png", "0001.heic", "0002.jpg"]
        )
    }

    @MainActor
    func testFrameAnimationCanRemoveAnIndividualFrame() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let assetID = try store.importVisualAsset(from: [fixturePNGURL, fixturePNGURL])
        XCTAssertEqual(store.importedVisualAsset(for: assetID)?.frameCount, 2)

        try store.removeFrame(assetID: assetID, at: 1)

        XCTAssertEqual(store.importedVisualAsset(for: assetID)?.frameCount, 1)
        XCTAssertThrowsError(try store.removeFrame(assetID: assetID, at: 0)) { error in
            guard case PetAssetStoreError.lastFrameRemovalUnsupported = error else {
                return XCTFail("Expected the final-frame deletion guard, got \(error)")
            }
        }
    }

    @MainActor
    func testActionAnimationAssetPersistsWithItsDefaultVisual() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let defaultAssetID = try store.importVisualAsset(from: [fixturePNGURL])
        let actionAssetID = try store.importVisualAsset(from: [fixturePNGURL, fixturePNGURL])
        let configuration = PetVisualConfiguration(
            states: [
                .normal: PetStateVisualConfiguration(
                    base: .importedAsset(id: defaultAssetID),
                    eyes: nil,
                    actionAssetID: actionAssetID,
                    actionAnimationPlaybackRate: 0.8
                )
            ]
        )

        let pet = try store.createCustomPet(name: "Action Pet", visualConfiguration: configuration)
        let reloadedStore = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let reloadedState = reloadedStore.customPet(id: pet.id)?.visualConfiguration.configuration(for: .normal)

        XCTAssertEqual(reloadedState?.actionAssetID, actionAssetID)
        XCTAssertEqual(reloadedState?.actionAnimationPlaybackRate, 0.8)
        XCTAssertNotNil(reloadedStore.importedVisualAsset(for: actionAssetID))
    }

    @MainActor
    func testMultipleActionAssetsPersistInTheirAddedOrder() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let defaultAssetID = try store.importVisualAsset(from: [fixturePNGURL])
        let firstActionID = try store.importVisualAsset(from: [fixturePNGURL])
        let secondActionID = try store.importVisualAsset(from: [fixturePNGURL, fixturePNGURL])
        var state = PetStateVisualConfiguration(
            base: .importedAsset(id: defaultAssetID),
            eyes: nil
        )
        state.appendActionAsset(firstActionID)
        state.appendActionAsset(secondActionID)
        state.actionFrequency = .high

        let pet = try store.createCustomPet(
            name: "Multiple Actions",
            visualConfiguration: PetVisualConfiguration(states: [.normal: state])
        )
        let reloadedStore = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let reloadedState = try XCTUnwrap(
            reloadedStore.customPet(id: pet.id)?.visualConfiguration.configuration(for: .normal)
        )

        XCTAssertEqual(reloadedState.resolvedActionAssetIDs, [firstActionID, secondActionID])
        XCTAssertEqual(reloadedState.resolvedActionFrequency, .high)
        XCTAssertNotNil(reloadedStore.importedVisualAsset(for: secondActionID))
    }

    @MainActor
    func testSleepingBreathPreferencePersistsForCustomPet() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let assetID = try store.importPNG(from: fixturePNGURL)
        var sleepingState = PetStateVisualConfiguration(
            base: .importedAsset(id: assetID),
            eyes: nil
        )
        sleepingState.sleepingBreathEnabled = false
        let pet = try store.createCustomPet(
            name: "No Breathing",
            visualConfiguration: PetVisualConfiguration(
                states: [
                    .normal: PetStateVisualConfiguration(
                        base: .importedAsset(id: assetID),
                        eyes: nil
                    ),
                    .sleeping: sleepingState
                ]
            )
        )

        let reloadedStore = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let reloadedState = try XCTUnwrap(
            reloadedStore.customPet(id: pet.id)?.visualConfiguration.configuration(for: .sleeping)
        )

        XCTAssertFalse(reloadedState.resolvedSleepingBreathEnabled)
    }

    func testOnlyStillImagesSupportSleepingBreath() {
        let stillImage = PetImportedVisualAsset(
            kind: .stillImage,
            imageURL: fixturePNGURL,
            frameURLs: []
        )
        let frameAnimation = PetImportedVisualAsset(
            kind: .frameAnimation,
            imageURL: fixturePNGURL,
            frameURLs: [fixturePNGURL, fixturePNGURL]
        )

        XCTAssertTrue(stillImage.supportsSleepingBreath)
        XCTAssertFalse(frameAnimation.supportsSleepingBreath)
    }

    func testLegacySleepingConfigurationDefaultsToBubbleEffect() {
        let configuration = PetStateVisualConfiguration(
            base: .officialSkin,
            eyes: nil
        )

        XCTAssertEqual(configuration.resolvedSleepingEffect, .bubbles)
    }

    @MainActor
    func testSleepingEffectPreferencePersistsForCustomPet() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let assetID = try store.importPNG(from: fixturePNGURL)
        var sleepingState = PetStateVisualConfiguration(
            base: .importedAsset(id: assetID),
            eyes: nil
        )
        sleepingState.sleepingEffect = .zzz
        let pet = try store.createCustomPet(
            name: "Zzz Effect",
            visualConfiguration: PetVisualConfiguration(
                states: [
                    .normal: PetStateVisualConfiguration(
                        base: .importedAsset(id: assetID),
                        eyes: nil
                    ),
                    .sleeping: sleepingState
                ]
            )
        )

        let reloadedStore = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        let reloadedState = try XCTUnwrap(
            reloadedStore.customPet(id: pet.id)?.visualConfiguration.configuration(for: .sleeping)
        )

        XCTAssertEqual(reloadedState.resolvedSleepingEffect, .zzz)
    }

    @MainActor
    func testCustomizationEntitlementIsAvailableByDefault() {
        XCTAssertTrue(FeatureEntitlementStore().isUnlocked(.petCustomization))
    }

    @MainActor
    func testFreeBuiltInPetsAreUnlockedButPaidPetAndSkinsStayLocked() {
        let suiteName = "PetProgressStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = PetProgressStore(
            currentRuntime: 0,
            selectedPetID: PetCatalog.cube.id,
            selectedSkinID: PetCatalog.cube.skins[0].id,
            defaults: defaults
        )

        XCTAssertTrue(store.ownsPet(PetCatalog.cube.id))
        XCTAssertFalse(store.ownsPet(PetCatalog.frog.id))
        XCTAssertTrue(store.ownsPet(PetCatalog.cat.id))
        XCTAssertTrue(store.ownsPet(PetCatalog.dog.id))
        XCTAssertTrue(store.ownsPet(PetCatalog.cookie.id))
        XCTAssertFalse(store.ownsSkin("frog.classic"))
        XCTAssertTrue(store.ownsSkin("cat.classic"))
        XCTAssertTrue(store.ownsSkin("cat.yellow"))
        XCTAssertFalse(store.ownsSkin("cat.grayTabby"))
        XCTAssertFalse(store.ownsSkin("cat.calico"))
        XCTAssertFalse(store.ownsSkin("cat.black"))
        XCTAssertFalse(store.ownsSkin("cat.siamese"))
        XCTAssertTrue(
            PetCatalog.cat.skins
                .filter { $0.id != "cat.classic" && $0.id != "cat.yellow" }
                .allSatisfy { $0.price > 0 }
        )
    }

    func testYellowCatOfficialDefaultsUseBakedStateArtwork() {
        var configuration = PetVisualDefaults.cat(skinID: "cat.yellow")

        XCTAssertTrue(configuration.resolvedBottomPetEnabled)
        XCTAssertFalse(configuration.resolvedMusicSwayingEnabled)
        configuration.setMusicSwayingEnabled(true)
        XCTAssertTrue(configuration.resolvedMusicSwayingEnabled)
        for state in PetVisualState.allCases {
            XCTAssertNil(configuration.configuration(for: state).eyes)
        }
        XCTAssertEqual(
            configuration.configuration(for: .normal).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.1515151515151515)
        )
        XCTAssertEqual(
            configuration.configuration(for: .happy).baseOffset,
            NormalizedVisualOffset(x: 0.015151515151515152, y: 0.16666666666666663)
        )
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.159090909090909)
        )
        XCTAssertEqual(
            configuration.configuration(for: .eating).base,
            .bundledAsset(name: "CatPetYellowEatingOfficial689cdacb")
        )
        for state in PetVisualState.allCases {
            XCTAssertEqual(configuration.configuration(for: state).resolvedBaseScale, 1.1)
        }
    }

    func testRestoringYellowMusicSwayingUsesItsOfficialDefault() {
        let official = PetVisualDefaults.cat(skinID: "cat.yellow")
        var configuration = official
        configuration.setMusicSwayingEnabled(true)

        configuration.restoreMusicSwayingEnabled(from: official)

        XCTAssertFalse(configuration.resolvedMusicSwayingEnabled)
    }

    func testDogIncludesShibaAndBeagleSkins() throws {
        XCTAssertEqual(PetCatalog.dog.name, .dog)
        XCTAssertEqual(PetCatalog.dog.skins.map(\.name), [.shibaClassic, .beagle])

        let configuration = PetVisualDefaults.configuration(
            petID: PetCatalog.dog.id,
            skinID: "dog.shiba"
        )
        let normalEyes = try XCTUnwrap(configuration.configuration(for: .normal).eyes)

        XCTAssertEqual(normalEyes.kind, .shibaWatercolor)
        XCTAssertEqual(configuration.configuration(for: .normal).base, .bundledAsset(name: "ShibaPet"))
    }

    @MainActor
    func testLegacyShibaOverrideKeepsItsEditsAndRestoresBundledArtwork() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(fileManager: fileManager, customRootURL: temporaryRoot)
        var legacy = PetVisualConfiguration(
            states: [.normal: PetStateVisualConfiguration(base: .officialSkin, eyes: nil)]
        )
        legacy.setBottomPetEnabled(true)
        try store.saveVisualOverride(legacy, petID: PetCatalog.dog.id, skinID: "dog.shiba")

        let restored = store.visualConfiguration(
            petID: PetCatalog.dog.id,
            skinID: "dog.shiba",
            official: PetVisualDefaults.shiba
        )
        XCTAssertEqual(restored.configuration(for: .normal).base, .bundledAsset(name: "ShibaPet"))
        XCTAssertTrue(restored.resolvedBottomPetEnabled)
    }

    func testBeagleOfficialDefaultsMatchApprovedCustomPetLayout() throws {
        let configuration = PetVisualDefaults.configuration(
            petID: PetCatalog.dog.id,
            skinID: "dog.beagle"
        )
        let normalEyes = try XCTUnwrap(configuration.configuration(for: .normal).eyes)

        XCTAssertEqual(PetCatalog.dog.skins.last?.name, .beagle)
        XCTAssertEqual(
            configuration.configuration(for: .normal).base,
            .bundledAsset(name: "BeaglePetNormal")
        )
        XCTAssertEqual(
            configuration.configuration(for: .happy).base,
            .bundledAsset(name: "BeaglePetHappy")
        )
        XCTAssertEqual(
            configuration.configuration(for: .scared).base,
            .bundledAsset(name: "BeaglePetScared")
        )
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).base,
            .bundledAsset(name: "BeaglePetSleeping")
        )
        XCTAssertEqual(
            configuration.configuration(for: .eating).base,
            .bundledAsset(name: "BeaglePetEating")
        )
        XCTAssertEqual(
            configuration.configuration(for: .hungry).base,
            .bundledAsset(name: "BeaglePetHungry")
        )
        XCTAssertEqual(normalEyes.kind, .catDefault)
        XCTAssertEqual(normalEyes.center.x, 0.47362294823232326)
        XCTAssertEqual(normalEyes.center.y, 0.3209635416666667)
        XCTAssertEqual(normalEyes.scale, 0.9880995639534884)
        XCTAssertEqual(normalEyes.spacing, -0.42475328947368496)
        XCTAssertEqual(normalEyes.resolvedOuterEyeScale, 0.9554764597039475)
        XCTAssertEqual(normalEyes.resolvedPupilScale, 0.670178865131579)
        XCTAssertEqual(normalEyes.resolvedPupilSpacing, -1.263928865131579)
        XCTAssertEqual(normalEyes.resolvedPupilGazeScale, 0.30499588815789475)
        XCTAssertEqual(configuration.configuration(for: .scared).resolvedBaseScale, 1.05)
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.1515151515151515)
        )
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).resolvedSleepingEffect,
            .bubbles
        )
    }

    func testSiameseOfficialDefaultsMatchApprovedEditorPlacement() throws {
        let configuration = PetVisualDefaults.cat(skinID: "cat.siamese")
        let normal = try XCTUnwrap(configuration.configuration(for: .normal).eyes)
        let happy = try XCTUnwrap(configuration.configuration(for: .happy).eyes)
        let scared = try XCTUnwrap(configuration.configuration(for: .scared).eyes)

        XCTAssertEqual(normal.center.x, 0.43367266414141414)
        XCTAssertEqual(normal.center.y, 0.3266256313131313)
        XCTAssertEqual(happy.center.x, 0.43211410984848486)
        XCTAssertEqual(happy.center.y, 0.35108901515151514)
        XCTAssertEqual(scared.center.x, 0.4321338383838384)
        XCTAssertEqual(scared.center.y, 0.3512863005050505)
        XCTAssertEqual(normal.spacing, -2.8)
        XCTAssertEqual(happy.spacing, -2.8)
        XCTAssertEqual(scared.scale, 0.743798828125)
        XCTAssertEqual(scared.spacing, -0.1447265625000007)
        XCTAssertNil(configuration.configuration(for: .sleeping).eyes)
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.16666666666666657)
        )
        XCTAssertNil(configuration.configuration(for: .eating).eyes)
        XCTAssertNil(configuration.configuration(for: .hungry).eyes)
    }

    func testOrangeTabbyOfficialDefaultsMatchApprovedEditorPlacement() throws {
        let configuration = PetVisualDefaults.cat(skinID: "cat.classic")
        let normal = try XCTUnwrap(configuration.configuration(for: .normal).eyes)
        let happy = try XCTUnwrap(configuration.configuration(for: .happy).eyes)
        let scared = try XCTUnwrap(configuration.configuration(for: .scared).eyes)

        XCTAssertEqual(normal.center.x, 0.49242424242424243)
        XCTAssertEqual(normal.center.y, 0.3181818181818182)
        XCTAssertEqual(normal.spacing, -1.2937959558823522)
        XCTAssertEqual(normal.resolvedOuterEyeScale, 1.2254566865808822)
        XCTAssertEqual(normal.resolvedPupilScale, 0.8321030560661764)
        XCTAssertEqual(happy.center.x, 0.4916942866161616)
        XCTAssertEqual(happy.center.y, 0.32733585858585856)
        XCTAssertEqual(happy.spacing, -0.8687040441176457)
        XCTAssertEqual(scared.scale, 0.841021369485294)
        XCTAssertEqual(scared.spacing, -0.8755974264705877)
        XCTAssertEqual(scared.resolvedColorMode, .black)
        XCTAssertNil(configuration.configuration(for: .sleeping).eyes)
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.14393939393939387)
        )
        XCTAssertNil(configuration.configuration(for: .eating).eyes)
        XCTAssertNil(configuration.configuration(for: .hungry).eyes)
    }

    func testGrayTabbyOfficialDefaultsMatchApprovedEditorPlacement() throws {
        let configuration = PetVisualDefaults.cat(skinID: "cat.grayTabby")
        let normal = try XCTUnwrap(configuration.configuration(for: .normal).eyes)
        let happy = try XCTUnwrap(configuration.configuration(for: .happy).eyes)
        let scared = try XCTUnwrap(configuration.configuration(for: .scared).eyes)

        XCTAssertEqual(normal.center.x, 0.46894728535353536)
        XCTAssertEqual(normal.center.y, 0.19986979166666666)
        XCTAssertEqual(normal.spacing, -1.972794117647057)
        XCTAssertEqual(normal.resolvedPupilScale, 0.677734375)
        XCTAssertEqual(happy.center.x, 0.4727272727272727)
        XCTAssertEqual(happy.center.y, 0.2393939393939394)
        XCTAssertEqual(happy.spacing, -2.8)
        XCTAssertEqual(scared.center.x, 0.46888809974747475)
        XCTAssertEqual(scared.center.y, 0.22492503156565657)
        XCTAssertEqual(scared.scale, 0.7711827895220588)
        XCTAssertEqual(scared.spacing, 0.3169577205882348)
        XCTAssertNil(configuration.configuration(for: .sleeping).eyes)
        XCTAssertEqual(
            configuration.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.06060606060606061)
        )
        XCTAssertNil(configuration.configuration(for: .eating).eyes)
        XCTAssertNil(configuration.configuration(for: .hungry).eyes)
    }

    func testCalicoAndBlackOfficialDefaultsUseApprovedLayouts() throws {
        let calico = PetVisualDefaults.cat(skinID: "cat.calico")
        let calicoNormal = try XCTUnwrap(calico.configuration(for: .normal).eyes)
        let calicoEating = try XCTUnwrap(calico.configuration(for: .eating).eyes)

        XCTAssertEqual(calicoNormal.center.x, 0.4424715909090909)
        XCTAssertEqual(calicoNormal.center.y, 0.27434501262626265)
        XCTAssertEqual(calicoNormal.resolvedPupilScale, 0.6925551470588235)
        XCTAssertEqual(calicoEating.resolvedOuterEyeScale, 0.917580997242647)
        XCTAssertEqual(calicoEating.resolvedPupilScale, 0.641802619485294)
        XCTAssertNil(calico.configuration(for: .sleeping).eyes)
        XCTAssertEqual(
            calico.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.14393939393939387)
        )
        XCTAssertNil(calico.configuration(for: .hungry).eyes)

        let black = PetVisualDefaults.cat(skinID: "cat.black")
        let blackHappy = try XCTUnwrap(black.configuration(for: .happy).eyes)
        let blackScared = try XCTUnwrap(black.configuration(for: .scared).eyes)

        XCTAssertEqual(blackHappy.scale, 0.8814338235294117)
        XCTAssertEqual(blackHappy.spacing, -1.2708180147058812)
        XCTAssertEqual(blackScared.scale, 0.6742446001838235)
        XCTAssertEqual(blackScared.spacing, 0.5226102941176496)
        XCTAssertNil(black.configuration(for: .sleeping).eyes)
        XCTAssertEqual(
            black.configuration(for: .sleeping).baseOffset,
            NormalizedVisualOffset(x: 0, y: 0.20454545454545442)
        )
        XCTAssertNil(black.configuration(for: .eating).eyes)
        XCTAssertNil(black.configuration(for: .hungry).eyes)
    }

    func testScaredExpressionUsesDedicatedVisualStateAndOfficialEyes() throws {
        XCTAssertEqual(PetVisualState(expression: .scared), .scared)

        let scaredEyes = try XCTUnwrap(
            PetVisualDefaults.cube.configuration(for: .scared).eyes
        )
        XCTAssertEqual(scaredEyes.kind, .scared)
        let styles = scaredEyes.eyeStyles(for: .calm)
        XCTAssertEqual(styles.left, .chevronRight)
        XCTAssertEqual(styles.right, .chevronLeft)
    }

    func testListeningExpressionUsesHappyVisualState() {
        XCTAssertEqual(PetVisualState(expression: .listening), .happy)
    }

    @MainActor
    func testHungryPetDoesNotBecomeHappyWhenClicked() {
        let state = PetState()

        state.reactToClick(isHungry: true)
        XCTAssertEqual(state.expression, .calm)

        state.reactToClick(isHungry: false)
        XCTAssertEqual(state.expression, .happy)
    }

    func testHungryVisualExpressionOverridesNonEatingExpressions() {
        for expression in PetExpression.allCases where expression != .hungry {
            XCTAssertEqual(
                PetView.visualExpression(base: expression, isHungry: true, isEating: false),
                .hungry,
                "Hungry pets should use the hungry appearance instead of \(expression)."
            )
        }
    }

    func testEatingVisualExpressionOverridesHungryExpression() {
        XCTAssertEqual(
            PetView.visualExpression(base: .sleeping, isHungry: true, isEating: true),
            .sleeping
        )
    }

    func testSleepingDecorationVisibilityKeepsOnlyRequestedPetsVisible() {
        XCTAssertTrue(
            PetView.decorationsAreVisible(
                petID: PetCatalog.cube.id,
                skinID: "cube.classic",
                expression: .sleeping
            )
        )
        XCTAssertTrue(
            PetView.decorationsAreVisible(
                petID: PetCatalog.frog.id,
                skinID: "frog.classic",
                expression: .sleeping
            )
        )
        XCTAssertTrue(
            PetView.decorationsAreVisible(
                petID: PetCatalog.cat.id,
                skinID: "cat.yellow",
                expression: .sleeping
            )
        )

        let petsThatHideSleepingDecorations = [
            (PetCatalog.cat.id, "cat.classic"),
            (PetCatalog.dog.id, "dog.shiba"),
            (PetCatalog.cookie.id, "cookie.classic"),
            ("custom:test", "custom:test")
        ]
        for (petID, skinID) in petsThatHideSleepingDecorations {
            XCTAssertFalse(
                PetView.decorationsAreVisible(
                    petID: petID,
                    skinID: skinID,
                    expression: .sleeping
                )
            )
            XCTAssertTrue(
                PetView.decorationsAreVisible(
                    petID: petID,
                    skinID: skinID,
                    expression: .calm
                )
            )
        }
    }

    func testFoodSatietyIncreasesWithPrice() {
        XCTAssertEqual(ShopCatalog.food(id: "food.smallCookie")?.satiety, 18)
        XCTAssertEqual(ShopCatalog.food(id: "food.energyBar")?.satiety, 38)
        XCTAssertEqual(ShopCatalog.food(id: "food.nutritionCan")?.satiety, 75)
        XCTAssertEqual(ShopCatalog.food(id: "food.fishShapedPastry")?.satiety, 30)
        XCTAssertEqual(ShopCatalog.food(id: "food.puddingCup")?.satiety, 45)
        XCTAssertEqual(ShopCatalog.food(id: "food.threeColorDango")?.satiety, 56)

        let foodsByPrice = ShopCatalog.foods.sorted { $0.price < $1.price }
        XCTAssertTrue(zip(foodsByPrice, foodsByPrice.dropFirst()).allSatisfy { cheaper, pricier in
            cheaper.price < pricier.price && cheaper.satiety < pricier.satiety
        })
    }

    @MainActor
    func testHungerStoreDecaysAndFeedsSatiety() {
        let suiteName = "PetHungerStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let start = Date(timeIntervalSinceReferenceDate: 10_000)
        let store = PetHungerStore(defaults: defaults, now: start)
        XCTAssertEqual(store.satiety, 100)
        XCTAssertFalse(store.isHungry)

        store.refresh(now: start.addingTimeInterval(10 * 3_600))
        XCTAssertEqual(store.satiety, 20)
        XCTAssertTrue(store.isHungry)

        let gained = store.feed(ShopCatalog.foods[1], now: start.addingTimeInterval(10 * 3_600 + 60))
        XCTAssertEqual(gained, 38)
        XCTAssertEqual(store.satiety, 58)
        XCTAssertFalse(store.isHungry)

        let cappedGain = store.feed(ShopCatalog.foods[2], now: start.addingTimeInterval(10 * 3_600 + 120))
        XCTAssertEqual(cappedGain, 42)
        XCTAssertEqual(store.satiety, 100)
    }

    @MainActor
    func testOldOfficialOverrideInheritsNewScaredState() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        let oldOverride = PetVisualConfiguration(
            states: [
                .normal: PetStateVisualConfiguration(
                    base: .officialSkin,
                    eyes: PetEyeModuleConfiguration(kind: .tracking)
                )
            ]
        )
        try store.saveVisualOverride(
            oldOverride,
            petID: PetCatalog.cube.id,
            skinID: PetCatalog.cube.skins[0].id
        )

        let resolved = store.visualConfiguration(
            petID: PetCatalog.cube.id,
            skinID: PetCatalog.cube.skins[0].id,
            official: PetVisualDefaults.cube
        )
        XCTAssertEqual(resolved.configuration(for: .normal).eyes?.kind, .tracking)
        XCTAssertEqual(resolved.configuration(for: .scared).eyes?.kind, .scared)
        XCTAssertEqual(resolved.configuration(for: .eating).eyes?.kind, .eating)
    }

    @MainActor
    func testRestoringOneOfficialStatePreservesOtherStateAdjustments() throws {
        let fileManager = FileManager.default
        let temporaryRoot = fileManager.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? fileManager.removeItem(at: temporaryRoot) }

        let store = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        let official = PetVisualDefaults.cube
        var customized = official

        var normal = customized.configuration(for: .normal)
        var normalEyes = try XCTUnwrap(normal.eyes)
        normalEyes.center = NormalizedVisualPoint(x: 0.2, y: 0.3)
        normal.eyes = normalEyes
        customized.setConfiguration(normal, for: .normal)

        var happy = customized.configuration(for: .happy)
        var happyEyes = try XCTUnwrap(happy.eyes)
        happyEyes.center = NormalizedVisualPoint(x: 0.8, y: 0.7)
        happy.eyes = happyEyes
        customized.setConfiguration(happy, for: .happy)

        try store.saveVisualOverride(
            customized,
            petID: PetCatalog.cube.id,
            skinID: PetCatalog.cube.skins[0].id
        )

        var restoredDraft = store.visualConfiguration(
            petID: PetCatalog.cube.id,
            skinID: PetCatalog.cube.skins[0].id,
            official: official
        )
        restoredDraft.setConfiguration(
            official.configuration(for: .happy),
            for: .happy
        )
        try store.saveVisualOverride(
            restoredDraft,
            petID: PetCatalog.cube.id,
            skinID: PetCatalog.cube.skins[0].id
        )

        let reloadedStore = PetCustomizationStore(
            fileManager: fileManager,
            customRootURL: temporaryRoot
        )
        let restored = reloadedStore.visualConfiguration(
            petID: PetCatalog.cube.id,
            skinID: PetCatalog.cube.skins[0].id,
            official: official
        )

        XCTAssertEqual(restored.configuration(for: .normal).eyes?.center.x, 0.2)
        XCTAssertEqual(restored.configuration(for: .normal).eyes?.center.y, 0.3)
        XCTAssertEqual(
            restored.configuration(for: .happy),
            official.configuration(for: .happy)
        )
    }

    func testEatingStateFallsBackToNormalForLegacyCustomConfigurations() throws {
        let normal = PetStateVisualConfiguration(
            base: .officialSkin,
            eyes: PetEyeModuleConfiguration(kind: .tracking)
        )
        let configuration = PetVisualConfiguration(states: [.normal: normal])

        XCTAssertEqual(configuration.configuration(for: .eating), normal)
        XCTAssertEqual(PetVisualDefaults.cube.configuration(for: .eating).eyes?.kind, .eating)
    }

    func testEyeAlignmentSupportsIndependentOffsetsAndLegacyData() throws {
        let legacyData = Data(
            #"{"center":{"x":0.5,"y":0.4},"kind":"tracking","scale":1,"spacing":11}"#.utf8
        )
        var configuration = try JSONDecoder().decode(
            PetEyeModuleConfiguration.self,
            from: legacyData
        )

        XCTAssertTrue(configuration.areEyesAligned)
        XCTAssertEqual(configuration.resolvedColorMode, .automatic)
        XCTAssertEqual(configuration.resolvedOuterEyeScale, 1)
        XCTAssertEqual(configuration.resolvedPupilScale, 1)
        XCTAssertEqual(configuration.resolvedPupilSpacing, 0)
        XCTAssertEqual(configuration.resolvedPupilGazeScale, 1)
        configuration.setEyesAligned(false)
        XCTAssertFalse(configuration.areEyesAligned)
        XCTAssertEqual(configuration.leftEyeOffset, .zero)
        XCTAssertEqual(configuration.rightEyeOffset, .zero)

        configuration.leftEyeOffset = NormalizedVisualOffset(x: -0.1, y: 0.2)
        configuration.colorMode = .white
        configuration.outerEyeScale = 1.25
        configuration.pupilScale = 0.75
        configuration.pupilSpacing = 1.5
        configuration.pupilGazeScale = 0.4
        let roundTripData = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(
            PetEyeModuleConfiguration.self,
            from: roundTripData
        )
        XCTAssertEqual(decoded.leftEyeOffset, NormalizedVisualOffset(x: -0.1, y: 0.2))
        XCTAssertEqual(decoded.resolvedColorMode, .white)
        XCTAssertEqual(decoded.resolvedOuterEyeScale, 1.25)
        XCTAssertEqual(decoded.resolvedPupilScale, 0.75)
        XCTAssertEqual(decoded.resolvedPupilSpacing, 1.5)
        XCTAssertEqual(decoded.resolvedPupilGazeScale, 0.4)

        configuration.setEyesAligned(true)
        XCTAssertTrue(configuration.areEyesAligned)
        XCTAssertNil(configuration.leftEyeOffset)
        XCTAssertNil(configuration.rightEyeOffset)
    }

    func testCatDefaultEyeModuleUsesRoundEyesAndTracksThePointer() {
        let configuration = PetEyeModuleConfiguration(kind: .catDefault)

        XCTAssertEqual(configuration.eyeStyles(for: .calm).left, .round)
        XCTAssertEqual(configuration.eyeStyles(for: .calm).right, .round)
        XCTAssertTrue(configuration.followsMouse(for: .calm))
        XCTAssertTrue(configuration.allowsBlinking)
    }

    func testBlackSmallBlockEyeModuleKeepsTrackingGeometry() {
        let configuration = PetEyeModuleConfiguration(kind: .trackingBlack)

        XCTAssertEqual(configuration.eyeStyles(for: .calm).left, .round)
        XCTAssertEqual(configuration.eyeStyles(for: .calm).right, .round)
        XCTAssertTrue(configuration.followsMouse(for: .calm))
        XCTAssertTrue(configuration.allowsBlinking)
        XCTAssertTrue(configuration.usesFixedBlackColor)
        XCTAssertTrue(configuration.usesSingleColorEyeControls)
    }

    func testSelectableEyeColorsOnlyAppearForSupportedOfficialEyeTypes() {
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .tracking).supportsEyeColorSelection)
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .happy).supportsEyeColorSelection)
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .scared).supportsEyeColorSelection)
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .sleeping).supportsEyeColorSelection)
        XCTAssertFalse(PetEyeModuleConfiguration(kind: .catDefault).supportsEyeColorSelection)
        XCTAssertFalse(PetEyeModuleConfiguration(kind: .cookieBlackBean).supportsEyeColorSelection)
    }

    func testSelectableEyeColorsResolveLegacyAutomaticUsingRenderedDefault() {
        var configuration = PetEyeModuleConfiguration(kind: .happy)
        XCTAssertEqual(configuration.resolvedColorMode, .automatic)
        XCTAssertEqual(configuration.colorSelectionMode(automaticColor: .black), .black)
        XCTAssertEqual(configuration.colorSelectionMode(automaticColor: .white), .white)

        configuration.colorMode = .white
        XCTAssertEqual(configuration.colorSelectionMode(automaticColor: .black), .white)
        configuration.colorMode = .brown
        XCTAssertEqual(configuration.colorSelectionMode(automaticColor: .white), .brown)
    }

    func testHappyScaredAndSleepingEyesUseSingleColorDetailControls() {
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .happy).usesSingleColorEyeControls)
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .scared).usesSingleColorEyeControls)
        XCTAssertTrue(PetEyeModuleConfiguration(kind: .sleeping).usesSingleColorEyeControls)
    }

    func testBrownEyeColorRoundTrips() throws {
        var configuration = PetEyeModuleConfiguration(kind: .sleeping)
        configuration.colorMode = .brown

        let decoded = try JSONDecoder().decode(
            PetEyeModuleConfiguration.self,
            from: JSONEncoder().encode(configuration)
        )

        XCTAssertEqual(decoded.resolvedColorMode, .brown)
    }

    func testSkinOffsetSupportsLegacyDataAndRoundTrip() throws {
        let legacyData = Data(#"{"base":{"officialSkin":{}}}"#.utf8)
        var configuration = try JSONDecoder().decode(
            PetStateVisualConfiguration.self,
            from: legacyData
        )

        XCTAssertNil(configuration.baseOffset)
        configuration.baseOffset = NormalizedVisualOffset(x: -0.1, y: 0.2)
        XCTAssertEqual(configuration.resolvedBaseScale, 1)
        configuration.baseScale = 1.15

        let roundTripData = try JSONEncoder().encode(configuration)
        let decoded = try JSONDecoder().decode(
            PetStateVisualConfiguration.self,
            from: roundTripData
        )
        XCTAssertEqual(decoded.baseOffset, NormalizedVisualOffset(x: -0.1, y: 0.2))
        XCTAssertEqual(decoded.baseScale, 1.15)
    }

    private var fixturePNGURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Assets/FrogPet.png", isDirectory: false)
    }
}
