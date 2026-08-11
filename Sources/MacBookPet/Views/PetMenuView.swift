import SwiftUI

private enum PetMenuPage {
    case shop
    case inventory
    case myPets
}

struct PetMenuView: View {
    @ObservedObject var progressStore: PetProgressStore
    @ObservedObject var inventoryStore: PetInventoryStore
    @ObservedObject var languageSettings: LanguageSettings
    let useFood: (PetShopItemDefinition) -> Bool

    @State private var page: PetMenuPage = .shop
    @State private var selectedSection: PetShopSection = .food
    @State private var selectedDecorationCategory: PetDecorationCategory = .head
    @State private var warehouseFeedbackSequence = 0
    @State private var isWarehouseButtonResponding = false
    @State private var showsWarehouseIncrement = false

    private static let backgroundImage: NSImage? = {
        guard let url = PetResourceURLCache.url(
            named: "PetMenuBackground",
            withExtension: "jpg"
        ) else {
            return nil
        }
        return PetImportedImageCache.image(for: url)
    }()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footer
        }
        .frame(minWidth: 720, minHeight: 520)
        .background {
            menuBackground
        }
        .preferredColorScheme(.light)
    }

    private var menuBackground: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)

            if let image = Self.backgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        Color.white.opacity(0.10)
                    }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var header: some View {
        if page == .shop {
            Text("商店")
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
        } else {
            HStack(spacing: 12) {
                Text(page == .inventory ? "仓库" : "我的宠物")
                    .font(.title2.weight(.semibold))

                Spacer()

                Button {
                    page = .shop
                } label: {
                    Image(systemName: "xmark")
                        .frame(width: 18, height: 18)
                }
                .buttonStyle(PetMenuRaisedButtonStyle(isCompact: true))
                .accessibilityLabel("返回商店")
                .help("返回商店")
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
        }
    }

    @ViewBuilder
    private var content: some View {
        if page == .myPets {
            MyPetsView(
                progressStore: progressStore,
                inventoryStore: inventoryStore,
                languageSettings: languageSettings
            )
        } else {
            VStack(spacing: 14) {
                sectionButtons

                if selectedSection == .decoration {
                    decorationCategoryButtons
                }

                if page == .shop, selectedSection == .pet {
                    PetStoreCatalogView(
                        progressStore: progressStore,
                        languageSettings: languageSettings
                    )
                } else {
                    itemGrid
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

    private var sectionButtons: some View {
        HStack(spacing: 12) {
            ForEach(availableSections) { section in
                Button {
                    selectedSection = section
                } label: {
                    Text(section.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    PetMenuRaisedButtonStyle(isSelected: selectedSection == section)
                )
                .accessibilityValue(selectedSection == section ? "已选择" : "")
            }
        }
    }

    private var decorationCategoryButtons: some View {
        HStack(spacing: 12) {
            ForEach(PetDecorationCategory.allCases) { category in
                Button {
                    selectedDecorationCategory = category
                } label: {
                    Text(category.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(
                    PetMenuRaisedButtonStyle(isSelected: selectedDecorationCategory == category)
                )
                .accessibilityValue(selectedDecorationCategory == category ? "已选择" : "")
            }
        }
    }

    private var itemGrid: some View {
        let items = visibleItems

        return Group {
            if items.isEmpty {
                ContentUnavailableView(
                    page == .shop ? "暂无商品" : "暂无物品",
                    systemImage: page == .shop ? "bag" : "shippingbox"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: itemGridColumns,
                        spacing: 16
                    ) {
                        ForEach(items) { item in
                            if page == .shop {
                                PetShopItemCard(
                                    item: item,
                                    canPurchase: progressStore.coins >= item.price,
                                    purchase: {
                                        guard inventoryStore.purchase(item, using: progressStore) else {
                                            return nil
                                        }
                                        return inventoryStore.quantity(of: item.id)
                                    },
                                    purchaseSucceeded: showWarehousePurchaseFeedback
                                )
                            } else {
                                PetInventoryItemCard(
                                    item: item,
                                    quantity: inventoryStore.quantity(of: item.id),
                                    use: {
                                        useFood(item)
                                    }
                                )
                            }
                        }
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
            }
        }
    }

    private var itemGridColumns: [GridItem] {
        if selectedSection == .food {
            return Array(
                repeating: GridItem(.flexible(minimum: 148, maximum: 176), spacing: 16),
                count: 3
            )
        }

        return [GridItem(.adaptive(minimum: 148, maximum: 176), spacing: 16)]
    }

    private var visibleItems: [PetShopItemDefinition] {
        switch page {
        case .shop:
            ShopCatalog.petMenuItems(
                in: selectedSection,
                decorationCategory: selectedDecorationCategory
            )
        case .inventory:
            inventoryStore.ownedItems(
                in: selectedSection,
                decorationCategory: selectedDecorationCategory
            )
        case .myPets:
            []
        }
    }

    private var availableSections: [PetShopSection] {
        page == .shop ? PetShopSection.allCases : [.decoration, .food]
    }

    private var footer: some View {
        HStack {
            if page == .shop {
                Button {
                    page = .myPets
                } label: {
                    Label("我的宠物", systemImage: "pawprint.circle")
                }
                .buttonStyle(PetMenuRaisedButtonStyle())

                Spacer()

                Button {
                    if selectedSection == .pet {
                        selectedSection = .food
                    }
                    page = .inventory
                } label: {
                    Label("仓库", systemImage: "shippingbox")
                }
                .buttonStyle(PetMenuRaisedButtonStyle())
                .scaleEffect(isWarehouseButtonResponding ? 1.08 : 1)
                .overlay(alignment: .topTrailing) {
                    if showsWarehouseIncrement {
                        Text("+1")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(PetMenuCardPalette.coral)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(.regularMaterial, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(PetMenuCardPalette.coral.opacity(0.45))
                            }
                            .offset(x: 17, y: -15)
                            .transition(
                                .scale(scale: 0.75)
                                    .combined(with: .opacity)
                            )
                            .accessibilityHidden(true)
                    }
                }
            } else {
                Spacer()
            }
        }
        .frame(minHeight: 34)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func showWarehousePurchaseFeedback() {
        warehouseFeedbackSequence += 1
        let sequence = warehouseFeedbackSequence

        withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
            isWarehouseButtonResponding = true
            showsWarehouseIncrement = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            guard sequence == warehouseFeedbackSequence else { return }
            withAnimation(.easeOut(duration: 0.16)) {
                isWarehouseButtonResponding = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard sequence == warehouseFeedbackSequence else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                showsWarehouseIncrement = false
            }
        }
    }
}

private struct PetShopItemCard: View {
    let item: PetShopItemDefinition
    let canPurchase: Bool
    let purchase: () -> Int?
    let purchaseSucceeded: () -> Void

    @State private var isHovering = false
    @State private var purchasedQuantity: Int?
    @State private var purchaseFeedbackSequence = 0

    var body: some View {
        Button {
            guard let quantity = purchase() else { return }
            showPurchaseFeedback(quantity: quantity)
            purchaseSucceeded()
        } label: {
            ZStack {
                VStack(spacing: 8) {
                    PetShopItemIconView(item: item)
                    Text(item.name)
                        .font(.headline)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack {
                    HStack {
                        Spacer()
                        PetMenuCardPriceBadge(price: item.price)
                    }
                    Spacer()
                }
                .padding(9)

                VStack {
                    Spacer()
                    PetMenuCardHoverActionLabel(
                        title: purchaseActionTitle,
                        isVisible: isHovering || purchasedQuantity != nil,
                        isEnabled: purchasedQuantity != nil || canPurchase
                    )
                    .padding(.bottom, 11)
                }

                if purchasedQuantity != nil {
                    VStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                        Text("购买成功")
                            .font(.callout.weight(.bold))
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
                    .background(
                        PetMenuCardPalette.bisque.opacity(0.96),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(PetMenuCardPalette.coral.opacity(0.55))
                    }
                    .shadow(color: .black.opacity(0.16), radius: 6, x: 0, y: 3)
                    .offset(y: -5)
                    .transition(
                        .scale(scale: 0.82)
                            .combined(with: .opacity)
                    )
                    .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(PetMenuCardButtonStyle(isHovering: isHovering))
        .disabled(!canPurchase)
        .onHover { isHovering = $0 }
        .accessibilityLabel("\(item.name)，\(item.price)G")
        .accessibilityValue(accessibilityPurchaseValue)
        .accessibilityHint(
            purchasedQuantity != nil
                ? "购买成功"
                : canPurchase ? "点击购买" : "金币不足"
        )
    }

    private var purchaseActionTitle: String {
        guard let purchasedQuantity else { return "购买" }
        return "✓ 已放入仓库 ×\(purchasedQuantity)"
    }

    private var accessibilityPurchaseValue: String {
        guard let purchasedQuantity else { return "" }
        return "购买成功，仓库数量 \(purchasedQuantity)"
    }

    private func showPurchaseFeedback(quantity: Int) {
        purchaseFeedbackSequence += 1
        let sequence = purchaseFeedbackSequence

        withAnimation(.spring(response: 0.25, dampingFraction: 0.62)) {
            purchasedQuantity = quantity
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            guard sequence == purchaseFeedbackSequence else { return }
            withAnimation(.easeOut(duration: 0.18)) {
                purchasedQuantity = nil
            }
        }
    }
}

private struct PetInventoryItemCard: View {
    let item: PetShopItemDefinition
    let quantity: Int
    let use: () -> Bool

    @State private var isHovering = false

    @ViewBuilder
    var body: some View {
        if item.section == .food {
            Button {
                _ = use()
            } label: {
                cardContent(showsUseAction: true)
            }
            .buttonStyle(PetMenuCardButtonStyle(isHovering: isHovering))
            .onHover { isHovering = $0 }
            .accessibilityLabel("\(item.name)，数量 \(quantity)")
            .accessibilityHint("点击使用")
        } else {
            cardContent(showsUseAction: false)
                .petMenuCardSurface(isHovering: isHovering)
                .onHover { isHovering = $0 }
        }
    }

    private func cardContent(showsUseAction: Bool) -> some View {
        ZStack {
            VStack(spacing: 8) {
                PetShopItemIconView(item: item)
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Text("数量 \(quantity)")
                    .font(.subheadline)
                    .foregroundStyle(PetMenuCardPalette.coral.opacity(0.72))
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, showsUseAction ? 30 : 14)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if showsUseAction {
                VStack {
                    Spacer()
                    PetMenuCardHoverActionLabel(title: "使用", isVisible: isHovering)
                        .padding(.bottom, 11)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct PetShopItemIconView: View {
    let item: PetShopItemDefinition

    var body: some View {
        Group {
            switch item.icon {
            case let .food(foodName):
                Image(nsImage: DesktopFoodFile.icon(for: foodName))
                    .resizable()
                    .scaledToFit()
            case let .asset(name):
                PetAssetImageView(
                    url: PetResourceURLCache.url(named: name, withExtension: nil),
                    purpose: .listThumbnail(maxPixelSize: 160)
                ) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            case let .systemSymbol(name):
                Image(systemName: name)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 68, height: 68)
        .accessibilityLabel(item.name)
    }
}
