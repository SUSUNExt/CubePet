import AppKit
import CoreGraphics
import SwiftUI

@MainActor
final class PermissionSettingsWindowController {
    private let languageSettings: LanguageSettings
    private var window: NSWindow?

    init(languageSettings: LanguageSettings) {
        self.languageSettings = languageSettings
    }

    func show() {
        let rootView = PermissionSettingsView(
            languageSettings: languageSettings,
            isInputMonitoringAllowed: { CGPreflightListenEventAccess() },
            openInputMonitoringSettings: Self.openInputMonitoringSettings,
            openAutomationSettings: Self.openAutomationSettings,
            onClose: { [weak self] in self?.window?.close() }
        )
        let hostingController = NSHostingController(rootView: rootView)
        let window = self.window ?? NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 650),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = languageSettings.permissionSettingsText(.title)
        window.contentViewController = hostingController
        window.isReleasedWhenClosed = false
        if self.window == nil {
            window.center()
            self.window = window
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private static func openInputMonitoringSettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent")
    }

    private static func openAutomationSettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Automation")
    }

    private static func openSystemSettings(_ address: String) {
        guard let url = URL(string: address) else { return }
        NSWorkspace.shared.open(url)
    }
}
