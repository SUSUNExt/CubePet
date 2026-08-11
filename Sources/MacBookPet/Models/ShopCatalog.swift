import Foundation

enum FoodName: String, Codable, CaseIterable, Hashable {
    case smallCookie
    case energyBar
    case petCola
    case fishShapedPastry
    case puddingCup
    case threeColorDango
}

struct FoodDefinition: Identifiable {
    let id: String
    let name: FoodName
    let price: Int
    let experience: Int
    let satiety: Int
}

enum PetShopSection: String, Codable, CaseIterable, Identifiable {
    case decoration
    case food
    case pet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .decoration: "装饰"
        case .food: "食物"
        case .pet: "宠物"
        }
    }
}

enum PetDecorationCategory: String, Codable, CaseIterable, Identifiable {
    case head
    case neck
    case pendant
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .head: "头部"
        case .neck: "颈部"
        case .pendant: "挂饰"
        case .other: "其他"
        }
    }
}

enum PetShopItemIcon: Hashable {
    case food(FoodName)
    case asset(String)
    case systemSymbol(String)
}

struct PetShopItemDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let section: PetShopSection
    let decorationCategory: PetDecorationCategory?
    let icon: PetShopItemIcon
    let price: Int
}

enum ShopCatalog {
    static let decorations: [PetShopItemDefinition] = [
        PetShopItemDefinition(
            id: "decoration.head.pawBaseballCap",
            name: "红色爪印棒球帽",
            section: .decoration,
            decorationCategory: .head,
            icon: .asset("PetHeadPawBaseballCap.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.head.aviatorCap",
            name: "飞行员护目镜帽",
            section: .decoration,
            decorationCategory: .head,
            icon: .asset("PetHeadAviatorCap.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.head.leafNewsboyCap",
            name: "金黄叶子报童帽",
            section: .decoration,
            decorationCategory: .head,
            icon: .asset("PetHeadLeafNewsboyCap.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.scarf",
            name: "围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarf.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.mushroomScarf",
            name: "蘑菇围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfMushroom.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.flowerPlaidScarf",
            name: "格纹花朵围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfFlowerPlaid.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.blueStripeScarf",
            name: "蓝条纹围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfBlueStripe.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.creamFlowerScarf",
            name: "奶油花朵围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfCreamFlower.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.starTasselScarf",
            name: "星愿流苏围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfStarTassel.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.redStripeScarf",
            name: "红白条纹围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfRedStripe.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.rustKnitScarf",
            name: "红棕针织围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfRustKnit.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.colorfulPolkaDotScarf",
            name: "彩色波点围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfColorfulPolkaDot.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.koiWaveScarf",
            name: "锦鲤海浪围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfKoiWave.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.rockLightningScarf",
            name: "闪电摇滚围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfRockLightning.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.lemonLaceScarf",
            name: "柠檬花边围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfLemonLace.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.galaxyScarf",
            name: "星空围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfGalaxy.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.rainbowPomPomScarf",
            name: "彩虹毛球围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfRainbowPomPom.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.autumnPlaidScarf",
            name: "秋日格纹围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfAutumnPlaid.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.acornArgyleScarf",
            name: "松果菱格围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfAcornArgyle.png"),
            price: 30
        ),
        PetShopItemDefinition(
            id: "decoration.neck.strawberryHeartScarf",
            name: "草莓爱心围巾",
            section: .decoration,
            decorationCategory: .neck,
            icon: .asset("PetNeckScarfStrawberryHeart.png"),
            price: 30
        )
    ]

    static let foods = [
        FoodDefinition(id: "food.smallCookie", name: .smallCookie, price: 5, experience: 8, satiety: 18),
        FoodDefinition(id: "food.energyBar", name: .energyBar, price: 10, experience: 17, satiety: 38),
        // Keep the legacy ID so food files purchased before the rename remain valid.
        FoodDefinition(id: "food.nutritionCan", name: .petCola, price: 20, experience: 35, satiety: 75),
        FoodDefinition(id: "food.fishShapedPastry", name: .fishShapedPastry, price: 8, experience: 13, satiety: 30),
        FoodDefinition(id: "food.puddingCup", name: .puddingCup, price: 12, experience: 21, satiety: 45),
        FoodDefinition(id: "food.threeColorDango", name: .threeColorDango, price: 15, experience: 26, satiety: 56)
    ]

    static func food(id: String) -> FoodDefinition? {
        foods.first { $0.id == id }
    }

    /// The shared catalog used by the new pet shop and warehouse. Add future
    /// decorations or foods here; the views and inventory do not need to change.
    static let petMenuItems: [PetShopItemDefinition] = decorations + foods.map { food in
        PetShopItemDefinition(
            id: food.id,
            name: foodDisplayName(food.name),
            section: .food,
            decorationCategory: nil,
            icon: .food(food.name),
            price: food.price
        )
    }

    static func petMenuItem(id: String) -> PetShopItemDefinition? {
        petMenuItems.first { $0.id == id }
    }

    static func petMenuItems(
        in section: PetShopSection,
        decorationCategory: PetDecorationCategory? = nil
    ) -> [PetShopItemDefinition] {
        petMenuItems.filter { item in
            guard item.section == section else { return false }
            guard section == .decoration else { return true }
            return item.decorationCategory == decorationCategory
        }
    }

    private static func foodDisplayName(_ name: FoodName) -> String {
        switch name {
        case .smallCookie: "小饼干"
        case .energyBar: "能量棒"
        case .petCola: "宠物可乐"
        case .fishShapedPastry: "鱼形烧饼"
        case .puddingCup: "布丁杯"
        case .threeColorDango: "三色团子"
        }
    }
}
