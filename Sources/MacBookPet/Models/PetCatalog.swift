import AppKit

enum PetSkinName {
    case classic
    case blue
    case green
    case red
    case pink
    case ice
    case rainbow
    case ice2
    case rainbow2
    case frogClassic
    case catClassic
    case catGrayTabby
    case catCalico
    case catBlack
    case catSiamese
    case catYellow
    case shibaClassic
    case beagle
    case cookieClassic
}

enum PetName {
    case cube
    case frog
    case cat
    case dog
    case cookie
}

enum PetVisualKind {
    case cube
    case frog
    case cat
    case dog
    case cookie
}

enum CubeSkinStyle: Equatable {
    case solid
    case ice
    case rainbow
    case ice2
    case rainbow2

    init(skinID: String) {
        switch skinID {
        case "cube.ice":
            self = .ice
        case "cube.rainbow":
            self = .rainbow
        case "cube.ice2":
            self = .ice2
        case "cube.rainbow2":
            self = .rainbow2
        default:
            self = .solid
        }
    }
}

struct PetSkinDefinition: Identifiable {
    let id: String
    let name: PetSkinName
    let color: NSColor
    let unlockLevel: Int
    let price: Int

    func isUnlocked(at level: Int) -> Bool {
        level >= unlockLevel
    }
}

struct PetDefinition: Identifiable {
    let id: String
    let name: PetName
    let visualKind: PetVisualKind
    let price: Int
    let skins: [PetSkinDefinition]

    func skin(id: String) -> PetSkinDefinition? {
        skins.first { $0.id == id }
    }
}

enum PetCatalog {
    static let cube = PetDefinition(
        id: "cube",
        name: .cube,
        visualKind: .cube,
        price: 0,
        skins: [
            PetSkinDefinition(
                id: "cube.classic",
                name: .classic,
                color: .black,
                unlockLevel: 1,
                price: 0
            ),
            PetSkinDefinition(
                id: "cube.blue",
                name: .blue,
                color: NSColor(srgbRed: 0.12, green: 0.40, blue: 0.90, alpha: 1),
                unlockLevel: 2,
                price: 40
            ),
            PetSkinDefinition(
                id: "cube.green",
                name: .green,
                color: NSColor(srgbRed: 0.10, green: 0.68, blue: 0.34, alpha: 1),
                unlockLevel: 3,
                price: 80
            ),
            PetSkinDefinition(
                id: "cube.red",
                name: .red,
                color: NSColor(srgbRed: 0.88, green: 0.16, blue: 0.18, alpha: 1),
                unlockLevel: 5,
                price: 160
            ),
            PetSkinDefinition(
                id: "cube.pink",
                name: .pink,
                color: NSColor(srgbRed: 0.96, green: 0.38, blue: 0.66, alpha: 1),
                unlockLevel: 8,
                price: 300
            ),
            PetSkinDefinition(
                id: "cube.ice",
                name: .ice,
                color: NSColor(srgbRed: 0.62, green: 0.88, blue: 0.98, alpha: 1),
                unlockLevel: 1,
                price: 0
            ),
            PetSkinDefinition(
                id: "cube.rainbow",
                name: .rainbow,
                color: NSColor(srgbRed: 0.78, green: 0.34, blue: 0.92, alpha: 1),
                unlockLevel: 1,
                price: 0
            ),
            PetSkinDefinition(
                id: "cube.ice2",
                name: .ice2,
                color: NSColor(srgbRed: 0.31, green: 0.66, blue: 0.80, alpha: 1),
                unlockLevel: 1,
                price: 0
            ),
            PetSkinDefinition(
                id: "cube.rainbow2",
                name: .rainbow2,
                color: NSColor(srgbRed: 0.76, green: 0.19, blue: 0.32, alpha: 1),
                unlockLevel: 1,
                price: 0
            )
        ]
    )

    static let frog = PetDefinition(
        id: "frog",
        name: .frog,
        visualKind: .frog,
        price: 250,
        skins: [
            PetSkinDefinition(
                id: "frog.classic",
                name: .frogClassic,
                color: NSColor(srgbRed: 0.39, green: 0.48, blue: 0.16, alpha: 1),
                unlockLevel: 1,
                price: 0
            )
        ]
    )

    static let cat = PetDefinition(
        id: "cat",
        name: .cat,
        visualKind: .cat,
        price: 0,
        skins: [
            PetSkinDefinition(
                id: "cat.classic",
                name: .catClassic,
                color: NSColor(srgbRed: 0.94, green: 0.44, blue: 0.08, alpha: 1),
                unlockLevel: 1,
                price: 0
            ),
            PetSkinDefinition(
                id: "cat.grayTabby",
                name: .catGrayTabby,
                color: NSColor(srgbRed: 0.67, green: 0.62, blue: 0.54, alpha: 1),
                unlockLevel: 1,
                price: 30
            ),
            PetSkinDefinition(
                id: "cat.calico",
                name: .catCalico,
                color: NSColor(srgbRed: 0.91, green: 0.49, blue: 0.12, alpha: 1),
                unlockLevel: 1,
                price: 30
            ),
            PetSkinDefinition(
                id: "cat.black",
                name: .catBlack,
                color: NSColor(srgbRed: 0.07, green: 0.06, blue: 0.05, alpha: 1),
                unlockLevel: 1,
                price: 30
            ),
            PetSkinDefinition(
                id: "cat.siamese",
                name: .catSiamese,
                color: NSColor(srgbRed: 0.82, green: 0.72, blue: 0.56, alpha: 1),
                unlockLevel: 1,
                price: 30
            ),
            PetSkinDefinition(
                id: "cat.yellow",
                name: .catYellow,
                color: NSColor(srgbRed: 0.96, green: 0.66, blue: 0.14, alpha: 1),
                unlockLevel: 1,
                price: 0
            )
        ]
    )

    static let dog = PetDefinition(
        id: "dog",
        name: .dog,
        visualKind: .dog,
        price: 0,
        skins: [
            PetSkinDefinition(
                id: "dog.shiba",
                name: .shibaClassic,
                color: NSColor(srgbRed: 0.88, green: 0.42, blue: 0.12, alpha: 1),
                unlockLevel: 1,
                price: 0
            ),
            PetSkinDefinition(
                id: "dog.beagle",
                name: .beagle,
                color: NSColor(srgbRed: 0.73, green: 0.48, blue: 0.24, alpha: 1),
                unlockLevel: 1,
                price: 0
            )
        ]
    )

    static let cookie = PetDefinition(
        id: "cookie",
        name: .cookie,
        visualKind: .cookie,
        price: 0,
        skins: [
            PetSkinDefinition(
                id: "cookie.classic",
                name: .cookieClassic,
                color: NSColor(srgbRed: 0.89, green: 0.58, blue: 0.29, alpha: 1),
                unlockLevel: 1,
                price: 0
            )
        ]
    )

    static let pets = [cube, frog, cat, dog, cookie]

    static func pet(id: String) -> PetDefinition? {
        pets.first { $0.id == id }
    }
}
