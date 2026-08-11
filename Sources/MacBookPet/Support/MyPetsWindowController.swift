import AppKit
import SwiftUI

@MainActor
final class MyPetsWindowController {
    private let progressStore: PetProgressStore
    private let inventoryStore: PetInventoryStore
    private let languageSettings: LanguageSettings
    private var window: NSWindow?

    init(
        progressStore: PetProgressStore,
        inventoryStore: PetInventoryStore,
        languageSettings: LanguageSettings
    ) {
        self.progressStore = progressStore
        self.inventoryStore = inventoryStore
        self.languageSettings = languageSettings
    }

    func show() {
        let rootView = MyPetsView(
            progressStore: progressStore,
            inventoryStore: inventoryStore,
            languageSettings: languageSettings
        )
        let hostingController = NSHostingController(rootView: rootView)

        let window = self.window ?? NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "我的宠物"
        window.contentMinSize = NSSize(width: 700, height: 650)
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("MyPetsWindow")
        if self.window == nil {
            window.center()
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
