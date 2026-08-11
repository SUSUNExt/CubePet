import AppKit
import SwiftUI

@MainActor
final class PetMenuWindowController: NSObject, NSWindowDelegate {
    private let progressStore: PetProgressStore
    private let inventoryStore: PetInventoryStore
    private let languageSettings: LanguageSettings
    private let useFood: (PetShopItemDefinition) -> Bool
    private var window: NSWindow?

    init(
        progressStore: PetProgressStore,
        inventoryStore: PetInventoryStore,
        languageSettings: LanguageSettings,
        useFood: @escaping (PetShopItemDefinition) -> Bool
    ) {
        self.progressStore = progressStore
        self.inventoryStore = inventoryStore
        self.languageSettings = languageSettings
        self.useFood = useFood
        super.init()
    }

    func show() {
        let rootView = PetMenuView(
            progressStore: progressStore,
            inventoryStore: inventoryStore,
            languageSettings: languageSettings,
            useFood: useFood
        )
        let hostingController = NSHostingController(rootView: rootView)

        let window = self.window ?? NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "宠物菜单"
        window.appearance = NSAppearance(named: .aqua)
        window.contentMinSize = NSSize(width: 720, height: 520)
        window.contentViewController = hostingController
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("PetMenuWindow")
        if self.window == nil {
            window.center()
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        PetListThumbnailCache.removeAll()
        guard let closingWindow = notification.object as? NSWindow,
              closingWindow === window
        else { return }
        closingWindow.contentViewController = nil
    }
}
