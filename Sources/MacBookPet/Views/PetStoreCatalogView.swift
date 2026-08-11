import SwiftUI

private enum PetStoreCatalogMetrics {
    static let cardScale: CGFloat = 0.9
    static let minimumCardWidth: CGFloat = 148 * cardScale
    static let maximumCardWidth: CGFloat = 176 * cardScale
    static let thumbnailMaxPixelSize = 224
}

struct PetStoreCatalogView: View {
    @ObservedObject var progressStore: PetProgressStore
    @ObservedObject var languageSettings: LanguageSettings

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                ForEach(PetCatalog.pets) { pet in
                    PetStorePetSection(
                        pet: pet,
                        progressStore: progressStore,
                        languageSettings: languageSettings
                    )
                }
            }
            .padding(.bottom, 20)
        }
        .onDisappear {
            PetListThumbnailCache.removeAll()
        }
    }
}

private struct PetStorePetSection: View {
    let pet: PetDefinition
    @ObservedObject var progressStore: PetProgressStore
    @ObservedObject var languageSettings: LanguageSettings

    @State private var isExpanded = false

    private let columns = [
        GridItem(
            .adaptive(
                minimum: PetStoreCatalogMetrics.minimumCardWidth,
                maximum: PetStoreCatalogMetrics.maximumCardWidth
            ),
            spacing: 16
        )
    ]

    private var unlockedSkinCount: Int {
        pet.skins.count { progressStore.ownsSkin($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(
                        "\(languageSettings.petName(pet.name)) "
                            + "\(unlockedSkinCount)/\(pet.skins.count)"
                    )
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.18), value: isExpanded)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PetMenuRaisedButtonStyle(isSelected: isExpanded))
            .accessibilityValue(isExpanded ? "已展开" : "已收起")
            .accessibilityHint("已解锁 \(unlockedSkinCount) 个，共 \(pet.skins.count) 个皮肤")

            if isExpanded {
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(pet.skins) { skin in
                        PetStoreUnlockCard(
                            title: languageSettings.skinName(skin.name),
                            pet: pet,
                            skin: skin,
                            isUnlocked: progressStore.ownsSkin(skin.id),
                            price: purchasePrice(for: skin),
                            canPurchase: canPurchase(skin),
                            purchase: {
                                purchase(skin)
                            }
                        )
                    }
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func purchasePrice(for skin: PetSkinDefinition) -> Int {
        isDefaultSkin(skin) && !progressStore.ownsPet(pet.id)
            ? pet.price
            : skin.price
    }

    private func canPurchase(_ skin: PetSkinDefinition) -> Bool {
        if isDefaultSkin(skin) && !progressStore.ownsPet(pet.id) {
            return progressStore.canBuyPet(pet)
        }
        return progressStore.canBuySkin(skin, for: pet.id)
    }

    private func purchase(_ skin: PetSkinDefinition) -> Bool {
        if isDefaultSkin(skin) && !progressStore.ownsPet(pet.id) {
            return progressStore.buyPet(pet)
        }
        return progressStore.buySkin(skin, for: pet.id)
    }

    private func isDefaultSkin(_ skin: PetSkinDefinition) -> Bool {
        pet.skins.first?.id == skin.id
    }
}

private struct PetStoreUnlockCard: View {
    let title: String
    let pet: PetDefinition
    let skin: PetSkinDefinition
    let isUnlocked: Bool
    let price: Int
    let canPurchase: Bool
    let purchase: () -> Bool

    @State private var isHovering = false

    var body: some View {
        Button {
            guard !isUnlocked else { return }
            _ = purchase()
        } label: {
            ZStack {
                VStack(spacing: 8) {
                    OfficialPetArtworkView(
                        pet: pet,
                        skin: skin,
                        imagePurpose: .listThumbnail(
                            maxPixelSize: PetStoreCatalogMetrics.thumbnailMaxPixelSize
                        )
                    )
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, isUnlocked ? 14 : 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isUnlocked || canPurchase ? 1 : 0.68)

                VStack {
                    HStack {
                        Spacer()
                        if isUnlocked {
                            Text("已解锁")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(PetMenuCardPalette.coral.opacity(0.13), in: Capsule())
                        } else {
                            PetMenuCardPriceBadge(price: price)
                        }
                    }
                    Spacer()
                }
                .padding(9)

                if !isUnlocked {
                    VStack {
                        Spacer()
                        PetMenuCardHoverActionLabel(
                            title: "购买",
                            isVisible: isHovering,
                            isEnabled: canPurchase
                        )
                        .padding(.bottom, 11)
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PetMenuCardButtonStyle(isHovering: isHovering))
        .disabled(isUnlocked || !canPurchase)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(title)，\(isUnlocked ? "已解锁" : "\(price)G")")
        .accessibilityHint(isUnlocked ? "" : canPurchase ? "点击购买" : "金币不足")
    }
}
