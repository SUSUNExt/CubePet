import AppKit
import Combine

enum MenuFont: String, CaseIterable, Hashable {
    case system
    case hannotate
    case yuppy

    static let selectableCases: [MenuFont] = [.system, .hannotate, .yuppy]

    var menuFont: NSFont {
        let defaultFont = NSFont.menuFont(ofSize: 0)

        switch self {
        case .system:
            return defaultFont
        case .hannotate:
            return NSFont(name: "HannotateSC-W5", size: defaultFont.pointSize) ?? defaultFont
        case .yuppy:
            return NSFont(name: "YuppySC-Regular", size: defaultFont.pointSize) ?? defaultFont
        }
    }
}

final class MenuFontSettings: ObservableObject {
    private static let selectedFontKey = "MacBookPet.menuFont"

    @Published private(set) var font: MenuFont

    init() {
        let rawValue = UserDefaults.standard.string(forKey: Self.selectedFontKey)
        font = rawValue.flatMap(MenuFont.init(rawValue:)) ?? .system
    }

    func select(_ font: MenuFont) {
        self.font = font
        UserDefaults.standard.set(font.rawValue, forKey: Self.selectedFontKey)
    }
}
