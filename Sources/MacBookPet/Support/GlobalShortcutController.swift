import Carbon
import Foundation

final class GlobalShortcutController {
    private let settings: ShortcutSettings
    private let onShortcut: @MainActor () -> Void
    private let signature = OSType(
        UInt32(ascii: "C") << 24
            | UInt32(ascii: "P") << 16
            | UInt32(ascii: "e") << 8
            | UInt32(ascii: "t")
    )
    private var activeHotKeyID: UInt32?
    private var nextHotKeyID: UInt32 = 1
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    init(settings: ShortcutSettings, onShortcut: @escaping @MainActor () -> Void) {
        self.settings = settings
        self.onShortcut = onShortcut
        installEventHandler()
        registerInitialShortcut(settings.shortcut)
    }

    deinit {
        unregisterHotKey()
        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    private func installEventHandler() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return noErr }

                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )
                guard status == noErr else { return status }

                let controller = Unmanaged<GlobalShortcutController>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                controller.handle(hotKeyID: hotKeyID)
                return noErr
            },
            1,
            &eventSpec,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )
    }

    /// Registers a candidate before replacing the active hotkey, so a conflict
    /// cannot leave the user without their previous shortcut.
    @discardableResult
    func register(shortcut: KeyboardShortcutDefinition) -> Bool {
        guard shortcut.isValid else { return false }
        if hotKeyRef != nil, settings.shortcut == shortcut { return true }

        let eventHotKeyID = makeEventHotKeyID()
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &newHotKeyRef
        )

        guard status == noErr, let newHotKeyRef else { return false }

        let previousHotKeyRef = hotKeyRef
        hotKeyRef = newHotKeyRef
        activeHotKeyID = eventHotKeyID.id
        if let previousHotKeyRef {
            UnregisterEventHotKey(previousHotKeyRef)
        }
        settings.saveRegisteredShortcut(shortcut)
        return true
    }

    private func registerInitialShortcut(_ shortcut: KeyboardShortcutDefinition) {
        guard shortcut.isValid else { return }

        let eventHotKeyID = makeEventHotKeyID()
        var newHotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            eventHotKeyID,
            GetApplicationEventTarget(),
            0,
            &newHotKeyRef
        )

        guard status == noErr, let newHotKeyRef else { return }
        hotKeyRef = newHotKeyRef
        activeHotKeyID = eventHotKeyID.id
    }

    private func makeEventHotKeyID() -> EventHotKeyID {
        let id = nextHotKeyID
        nextHotKeyID &+= 1
        if nextHotKeyID == 0 {
            nextHotKeyID = 1
        }
        return EventHotKeyID(signature: signature, id: id)
    }

    private func unregisterHotKey() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        activeHotKeyID = nil
    }

    private func handle(hotKeyID: EventHotKeyID) {
        guard let activeHotKeyID, hotKeyID.signature == signature, hotKeyID.id == activeHotKeyID else { return }
        Task { @MainActor in
            onShortcut()
        }
    }
}

private extension UInt32 {
    init(ascii character: Character) {
        self = UInt32(character.asciiValue ?? 0)
    }
}
