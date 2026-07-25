import AppKit
import SwiftUI

@MainActor
final class ShortcutSettingsWindowController {
    private let shortcutSettings: ShortcutSettings
    private let languageSettings: LanguageSettings
    private let onSaveShortcut: (KeyboardShortcutDefinition) -> Bool
    private var window: NSWindow?

    init(
        shortcutSettings: ShortcutSettings,
        languageSettings: LanguageSettings,
        onSaveShortcut: @escaping (KeyboardShortcutDefinition) -> Bool
    ) {
        self.shortcutSettings = shortcutSettings
        self.languageSettings = languageSettings
        self.onSaveShortcut = onSaveShortcut
    }

    func show() {
        let rootView = ShortcutSettingsView(
            shortcutSettings: shortcutSettings,
            languageSettings: languageSettings,
            onSaveShortcut: onSaveShortcut,
            onClose: { [weak self] in self?.window?.close() }
        )
        let hostingController = NSHostingController(rootView: rootView)
        let window = self.window ?? NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 430, height: 260),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = languageSettings.text(.shortcutSettings)
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        if self.window == nil {
            window.center()
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
