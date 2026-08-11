import Combine
import Foundation

@MainActor
final class PetProgressStore: ObservableObject {
    private static let coinBalanceKey = "MacBookPet.coinBalance"
    private static let rewardedRuntimeKey = "MacBookPet.rewardedRuntime"
    private static let experienceKey = "MacBookPet.petExperience"
    private static let pendingFoodKey = "MacBookPet.pendingFood"
    private static let ownedPetsKey = "MacBookPet.ownedPets"
    private static let ownedSkinsKey = "MacBookPet.ownedSkins"
    private static let secondsPerCoin: TimeInterval = 5 * 60
    private static let experiencePerLevel = 100

    @Published private(set) var coins: Int
    @Published private(set) var experienceByPet: [String: Int]
    @Published private(set) var ownedPetIDs: Set<String>
    @Published private(set) var ownedSkinIDs: Set<String>

    var onChange: (() -> Void)?

    private var rewardedRuntime: TimeInterval
    private var pendingFoodByToken: [String: String]
    private var rewardTimer: Timer?
    private let defaults: UserDefaults

    init(
        currentRuntime: TimeInterval,
        selectedPetID: String,
        selectedSkinID: String,
        defaults: UserDefaults = .standard
    ) {
        self.defaults = defaults
        coins = defaults.integer(forKey: Self.coinBalanceKey)
        rewardedRuntime = defaults.double(forKey: Self.rewardedRuntimeKey)
        experienceByPet = Self.decodeDictionary(defaults.data(forKey: Self.experienceKey))
        pendingFoodByToken = Self.decodeStringDictionary(defaults.data(forKey: Self.pendingFoodKey))
        if let persistedPetIDs = defaults.stringArray(forKey: Self.ownedPetsKey) {
            ownedPetIDs = Set(persistedPetIDs)
        } else {
            ownedPetIDs = Set(PetCatalog.pets.filter { $0.price == 0 }.map(\.id))
        }
        ownedSkinIDs = Set(defaults.stringArray(forKey: Self.ownedSkinsKey) ?? [])

        // Existing selections remain owned even when they predate persisted
        // shop data. Paid pets added later stay locked for new users.
        ownedPetIDs.insert(selectedPetID)
        ownedSkinIDs.insert(selectedSkinID)
        for pet in PetCatalog.pets where ownedPetIDs.contains(pet.id) {
            ownedSkinIDs.formUnion(pet.skins.filter { $0.price == 0 }.map(\.id))
            if let firstSkinID = pet.skins.first?.id {
                ownedSkinIDs.insert(firstSkinID)
            }
        }

        synchronizeRuntime(currentRuntime)
        persist()
    }

    func start(runtimeProvider: @escaping () -> TimeInterval) {
        guard rewardTimer == nil else { return }

        let timer = Timer(timeInterval: 10, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.synchronizeRuntime(runtimeProvider())
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        rewardTimer = timer
    }

    func stop() {
        rewardTimer?.invalidate()
        rewardTimer = nil
        persist()
    }

    func synchronizeRuntime(_ currentRuntime: TimeInterval) {
        let unrewardedRuntime = max(0, currentRuntime - rewardedRuntime)
        let earnedCoins = Int(unrewardedRuntime / Self.secondsPerCoin)
        guard earnedCoins > 0 else { return }

        coins += earnedCoins
        rewardedRuntime += TimeInterval(earnedCoins) * Self.secondsPerCoin
        persist()
        onChange?()
    }

    func level(for petID: String) -> Int {
        1 + max(0, experienceByPet[petID, default: 0]) / Self.experiencePerLevel
    }

    func experienceProgress(for petID: String) -> Int {
        max(0, experienceByPet[petID, default: 0]) % Self.experiencePerLevel
    }

    func ownsPet(_ petID: String) -> Bool {
        ownedPetIDs.contains(petID)
    }

    func ownsSkin(_ skinID: String) -> Bool {
        ownedSkinIDs.contains(skinID)
    }

    func canBuyPet(_ pet: PetDefinition) -> Bool {
        !ownsPet(pet.id) && coins >= pet.price
    }

    func canBuySkin(_ skin: PetSkinDefinition, for petID: String) -> Bool {
        ownsPet(petID)
            && !ownsSkin(skin.id)
            && skin.isUnlocked(at: level(for: petID))
            && coins >= skin.price
    }

    @discardableResult
    func canAfford(_ food: FoodDefinition) -> Bool {
        coins >= food.price
    }

    @discardableResult
    func purchaseFood(_ food: FoodDefinition, token: String) -> Bool {
        guard pendingFoodByToken[token] == nil, spend(food.price) else { return false }

        pendingFoodByToken[token] = food.id
        persist()
        onChange?()
        return true
    }

    @discardableResult
    func purchasePetMenuItem(_ item: PetShopItemDefinition) -> Bool {
        guard ShopCatalog.petMenuItem(id: item.id) == item, spend(item.price) else {
            return false
        }

        persist()
        onChange?()
        return true
    }

    func canConsumeFood(
        _ payload: FoodFilePayload,
        for petID: String,
        allowUnownedPet: Bool = false
    ) -> Bool {
        (allowUnownedPet || ownsPet(petID))
            && pendingFoodByToken[payload.token] == payload.foodID
            && ShopCatalog.food(id: payload.foodID) != nil
    }

    func canReceiveInventoryFood(
        for petID: String,
        allowUnownedPet: Bool = false
    ) -> Bool {
        allowUnownedPet || ownsPet(petID)
    }

    @discardableResult
    func receiveInventoryFood(
        _ food: FoodDefinition,
        for petID: String,
        allowUnownedPet: Bool = false
    ) -> Int? {
        guard canReceiveInventoryFood(for: petID, allowUnownedPet: allowUnownedPet) else {
            return nil
        }

        experienceByPet[petID, default: 0] += food.experience
        persist()
        onChange?()
        return food.experience
    }

    @discardableResult
    func consumeFood(
        _ payload: FoodFilePayload,
        for petID: String,
        allowUnownedPet: Bool = false
    ) -> Bool {
        guard
            canConsumeFood(payload, for: petID, allowUnownedPet: allowUnownedPet),
            let food = ShopCatalog.food(id: payload.foodID)
        else { return false }

        pendingFoodByToken.removeValue(forKey: payload.token)
        experienceByPet[petID, default: 0] += food.experience
        persist()
        onChange?()
        return true
    }

    @discardableResult
    func buySkin(_ skin: PetSkinDefinition, for petID: String) -> Bool {
        guard canBuySkin(skin, for: petID), spend(skin.price) else { return false }

        ownedSkinIDs.insert(skin.id)
        persist()
        onChange?()
        return true
    }

    @discardableResult
    func buyPet(_ pet: PetDefinition) -> Bool {
        guard canBuyPet(pet), spend(pet.price) else { return false }

        ownedPetIDs.insert(pet.id)
        if let firstSkinID = pet.skins.first?.id {
            ownedSkinIDs.insert(firstSkinID)
        }
        persist()
        onChange?()
        return true
    }

    private func spend(_ amount: Int) -> Bool {
        guard amount >= 0, coins >= amount else { return false }
        coins -= amount
        return true
    }

    private func persist() {
        defaults.set(coins, forKey: Self.coinBalanceKey)
        defaults.set(rewardedRuntime, forKey: Self.rewardedRuntimeKey)
        defaults.set(Self.encodeDictionary(experienceByPet), forKey: Self.experienceKey)
        defaults.set(Self.encodeStringDictionary(pendingFoodByToken), forKey: Self.pendingFoodKey)
        defaults.set(Array(ownedPetIDs).sorted(), forKey: Self.ownedPetsKey)
        defaults.set(Array(ownedSkinIDs).sorted(), forKey: Self.ownedSkinsKey)
    }

    private static func encodeDictionary(_ dictionary: [String: Int]) -> Data? {
        try? JSONEncoder().encode(dictionary)
    }

    private static func decodeDictionary(_ data: Data?) -> [String: Int] {
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: Int].self, from: data)) ?? [:]
    }

    private static func encodeStringDictionary(_ dictionary: [String: String]) -> Data? {
        try? JSONEncoder().encode(dictionary)
    }

    private static func decodeStringDictionary(_ data: Data?) -> [String: String] {
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
}
