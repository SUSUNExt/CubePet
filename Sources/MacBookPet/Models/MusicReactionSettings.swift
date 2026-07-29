import Foundation

/// Global music-reaction preferences shared by every pet appearance.
struct MusicReactionSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var isSwayingEnabled: Bool = true
    var areMusicNotesEnabled: Bool = true
}
