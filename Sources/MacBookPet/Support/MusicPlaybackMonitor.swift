import AppKit
import CoreAudio

@MainActor
final class MusicPlaybackMonitor {
    private static let musicBundleIdentifier = "com.apple.Music"
    var onPlaybackChanged: ((Bool) -> Void)?

    private var timer: Timer?
    private var isCheckInFlight = false
    private var lastPublishedState: Bool?

    func start() {
        stop()
        checkPlaybackState()

        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkPlaybackState()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPlaybackState() {
        guard !isCheckInFlight else { return }

        let isAppleMusicRunning = !NSRunningApplication.runningApplications(
            withBundleIdentifier: Self.musicBundleIdentifier
        ).isEmpty
        let isSupportedThirdPartyMusicAppRunning = NSWorkspace.shared.runningApplications.contains {
            Self.isSupportedThirdPartyMusicApp(
                bundleIdentifier: $0.bundleIdentifier,
                displayName: $0.localizedName
            )
        }

        guard isAppleMusicRunning || isSupportedThirdPartyMusicAppRunning else {
            publish(false)
            return
        }

        isCheckInFlight = true
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let playbackStates = [
                isAppleMusicRunning ? Self.queryMusicPlaybackState() : nil,
                isSupportedThirdPartyMusicAppRunning
                    ? Self.querySupportedThirdPartyMusicPlaybackState()
                    : nil
            ]
            let isPlaying = Self.resolvedPlaybackState(playbackStates)

            DispatchQueue.main.async {
                guard let self else { return }
                self.isCheckInFlight = false

                self.publish(isPlaying)
            }
        }
    }

    private func publish(_ isPlaying: Bool) {
        guard lastPublishedState != isPlaying else { return }
        lastPublishedState = isPlaying
        onPlaybackChanged?(isPlaying)
    }

    private nonisolated static func queryMusicPlaybackState() -> Bool? {
        let source = """
        tell application id "com.apple.Music"
            if player state is playing then
                return "playing"
            end if
            return "notPlaying"
        end tell
        """

        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        guard error == nil else { return nil }
        return result.stringValue == "playing"
    }

    /// These players do not expose a player-state AppleScript dictionary. Their active
    /// audio output is the primary playback signal; the system Now Playing service is
    /// retained as a fallback for players that publish a session.
    private nonisolated static func querySupportedThirdPartyMusicPlaybackState() -> Bool? {
        if let isOutputRunning = querySupportedThirdPartyMusicAudioOutput() {
            return isOutputRunning
        }
        return querySupportedThirdPartyMusicNowPlayingState()
    }

    private nonisolated static func querySupportedThirdPartyMusicAudioOutput() -> Bool? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyProcessObjectList,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize
        ) == noErr else {
            return nil
        }

        let processCount = Int(dataSize) / MemoryLayout<AudioObjectID>.stride
        guard processCount > 0 else { return false }

        var processObjects = Array(repeating: AudioObjectID(), count: processCount)
        guard AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &dataSize,
            &processObjects
        ) == noErr else {
            return nil
        }

        var foundSupportedPlayer = false
        for processObject in processObjects {
            guard let bundleIdentifier = audioProcessBundleIdentifier(processObject) else {
                continue
            }
            guard isSupportedThirdPartyMusicApp(
                bundleIdentifier: bundleIdentifier,
                displayName: nil
            ) else {
                continue
            }

            foundSupportedPlayer = true
            if audioProcessIsRunningOutput(processObject) {
                return true
            }
        }

        return foundSupportedPlayer ? false : nil
    }

    private nonisolated static func audioProcessBundleIdentifier(
        _ processObject: AudioObjectID
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyBundleID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var bundleIdentifier: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)

        guard AudioObjectGetPropertyData(
            processObject,
            &address,
            0,
            nil,
            &dataSize,
            &bundleIdentifier
        ) == noErr else {
            return nil
        }
        return bundleIdentifier?.takeRetainedValue() as String?
    }

    private nonisolated static func audioProcessIsRunningOutput(
        _ processObject: AudioObjectID
    ) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioProcessPropertyIsRunningOutput,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var isRunning: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)

        guard AudioObjectGetPropertyData(
            processObject,
            &address,
            0,
            nil,
            &dataSize,
            &isRunning
        ) == noErr else {
            return false
        }
        return isRunning != 0
    }

    /// Fallback for supported players that do publish a Now Playing session.
    private nonisolated static func querySupportedThirdPartyMusicNowPlayingState() -> Bool? {
        let source = """
        use framework "AppKit"

        on run
            set mediaRemote to current application's NSBundle's bundleWithPath:"/System/Library/PrivateFrameworks/MediaRemote.framework/"
            mediaRemote's load()

            set nowPlayingRequest to current application's NSClassFromString("MRNowPlayingRequest")
            if nowPlayingRequest is missing value then return "unavailable"

            set playerPath to nowPlayingRequest's localNowPlayingPlayerPath()
            if playerPath is missing value then return "notPlaying"

            set client to playerPath's client()
            set bundleIdentifier to ""
            try
                set bundleIdentifier to client's bundleIdentifier() as text
            end try

            set displayName to ""
            try
                set displayName to client's displayName() as text
            end try

            set nowPlayingItem to nowPlayingRequest's localNowPlayingItem()
            if nowPlayingItem is missing value then return "notPlaying"

            set infoDict to nowPlayingItem's nowPlayingInfo()
            set playbackRate to infoDict's valueForKey:"kMRMediaRemoteNowPlayingInfoPlaybackRate"
            if playbackRate is missing value then return "notPlaying"

            return bundleIdentifier & linefeed & displayName & linefeed & (playbackRate as text)
        end run
        """

        guard let script = NSAppleScript(source: source) else { return nil }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)

        guard error == nil, let result = result.stringValue else { return nil }
        if result == "notPlaying" {
            return false
        }
        if result == "unavailable" {
            return nil
        }

        let components = result.split(separator: "\n", omittingEmptySubsequences: false)
        guard components.count == 3, let playbackRate = Double(components[2]) else {
            return nil
        }
        return isSupportedThirdPartyMusicApp(
            bundleIdentifier: String(components[0]),
            displayName: String(components[1])
        ) && playbackRate > 0
    }

    static nonisolated func isSupportedThirdPartyMusicApp(
        bundleIdentifier: String?,
        displayName: String?
    ) -> Bool {
        if let bundleIdentifier,
           [
                "com.netease.163music",
                "com.tencent.qqmusicmac",
                "com.kugou.kugou1002",
                "com.kugou.kugoumusic",
                "com.kugou.music"
           ].contains(bundleIdentifier.lowercased())
        {
            return true
        }

        guard let displayName else { return false }
        return [
            "neteasemusic",
            "网易云音乐",
            "qqmusic",
            "qq音乐",
            "kugoumusic",
            "kugou",
            "酷狗音乐"
        ].contains(
            displayName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        )
    }

    static nonisolated func resolvedPlaybackState(_ states: [Bool?]) -> Bool {
        states.contains(true)
    }

    deinit {
        timer?.invalidate()
    }
}
