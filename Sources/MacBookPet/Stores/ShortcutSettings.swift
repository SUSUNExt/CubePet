import Combine
import Foundation

final class ShortcutSettings: ObservableObject {
    private static let shortcutKey = "MacBookPet.menuShortcut"

    @Published private(set) var shortcut: KeyboardShortcutDefinition

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let data = defaults.data(forKey: Self.shortcutKey),
            let savedShortcut = try? JSONDecoder().decode(KeyboardShortcutDefinition.self, from: data),
            savedShortcut.isValid
        {
            shortcut = savedShortcut
        } else {
            shortcut = .defaultShortcut
        }
    }

    func saveRegisteredShortcut(_ shortcut: KeyboardShortcutDefinition) {
        guard shortcut.isValid else { return }
        self.shortcut = shortcut
        saveShortcut()
    }

    private func saveShortcut() {
        guard let data = try? JSONEncoder().encode(shortcut) else { return }
        defaults.set(data, forKey: Self.shortcutKey)
    }
}
