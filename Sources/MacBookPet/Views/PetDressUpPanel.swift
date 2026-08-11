import AppKit
import SwiftUI

struct PetDressUpPanel: View {
    let pet: PetDefinition
    let skin: PetSkinDefinition
    @ObservedObject var inventoryStore: PetInventoryStore
    let dismiss: () -> Void

    @State private var selectedCategory: PetDecorationCategory = .neck

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            HStack(alignment: .top, spacing: 20) {
                PetDressUpPreview(
                    pet: pet,
                    skin: skin,
                    inventoryStore: inventoryStore
                )
                warehouse
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .foregroundStyle(.primary)
        .background(Color(nsColor: .windowBackgroundColor))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var header: some View {
        HStack {
            Text("宠物打扮面板")
                .font(.headline)
            Spacer()
            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("关闭宠物打扮面板")
        }
        .frame(height: 46)
        .padding(.horizontal, 20)
    }

    private var warehouse: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("仓库")
                .font(.headline)

            Picker("装饰分类", selection: $selectedCategory) {
                ForEach(PetDecorationCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            let items = inventoryStore.ownedItems(
                in: .decoration,
                decorationCategory: selectedCategory
            )
            if items.isEmpty {
                ContentUnavailableView("仓库中暂无物品", systemImage: "shippingbox")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 82, maximum: 96), spacing: 10)],
                        spacing: 10
                    ) {
                        ForEach(items) { item in
                            PetDressUpWarehouseCard(
                                item: item,
                                quantity: inventoryStore.quantity(of: item.id)
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct PetDressUpPreview: View {
    private static let size = CGSize(width: 230, height: 230)
    private static let coordinateSpaceName = "pet-dress-up-preview"
    private static let artworkScale: CGFloat = 2.3

    let pet: PetDefinition
    let skin: PetSkinDefinition
    @ObservedObject var inventoryStore: PetInventoryStore

    var body: some View {
        ZStack {
            Color(red: 250.0 / 255.0, green: 244.0 / 255.0, blue: 239.0 / 255.0)

            OfficialPetArtworkView(pet: pet, skin: skin) {
                equippedDecorations
            }
                .scaleEffect(Self.artworkScale)
        }
        .frame(width: Self.size.width, height: Self.size.height)
        .coordinateSpace(name: Self.coordinateSpaceName)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(.separator, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .dropDestination(for: String.self) { itemIDs, location in
            equipFirstDecoration(itemIDs, at: location)
        }
    }

    private var normalPetBaseScale: CGFloat {
        CGFloat(
            PetVisualDefaults.configuration(petID: pet.id, skinID: skin.id)
                .configuration(for: .normal)
                .resolvedBaseScale
        )
    }

    private var previewGeometry: PetDressUpPreviewGeometry {
        PetDressUpPreviewGeometry(
            previewSize: Self.size,
            artworkScale: Self.artworkScale,
            petBaseScale: normalPetBaseScale
        )
    }

    private var bodyContentSize: CGSize {
        CGSize(width: PetMetrics.bodyContentSize, height: PetMetrics.bodyContentSize)
    }

    @ViewBuilder
    private var equippedDecorations: some View {
        ForEach(inventoryStore.equippedDecorations(for: pet.id, skinID: skin.id)) { decoration in
            if let item = ShopCatalog.petMenuItem(id: decoration.itemID) {
                DraggableEquippedDecorationView(
                    decoration: decoration,
                    item: item,
                    containerSize: bodyContentSize,
                    renderedSideLength: PetDecorationRenderingMetrics.sideLength(
                        decorationScale: decoration.scale
                    ),
                    dragBounds: CGRect(origin: .zero, size: Self.size),
                    gestureScale: normalPetBaseScale * Self.artworkScale,
                    coordinateSpaceName: Self.coordinateSpaceName,
                    move: { position in
                        inventoryStore.moveEquippedDecoration(
                            for: pet.id,
                            skinID: skin.id,
                            category: decoration.category,
                            to: position
                        )
                    },
                    resize: { scaleChange in
                        inventoryStore.resizeEquippedDecoration(
                            for: pet.id,
                            skinID: skin.id,
                            category: decoration.category,
                            by: scaleChange
                        )
                    },
                    remove: {
                        inventoryStore.unequipDecoration(
                            for: pet.id,
                            skinID: skin.id,
                            category: decoration.category
                        )
                    }
                )
            }
        }
    }

    private func equipFirstDecoration(_ itemIDs: [String], at location: CGPoint) -> Bool {
        guard
            CGRect(origin: .zero, size: Self.size).contains(location),
            let itemID = itemIDs.first,
            let item = ShopCatalog.petMenuItem(id: itemID),
            item.section == .decoration
        else { return false }

        return inventoryStore.equipDecoration(
            item,
            for: pet.id,
            skinID: skin.id,
            position: PetDecorationPosition(
                location: previewGeometry.bodyPoint(forPreviewPoint: location),
                in: bodyContentSize
            )
        ) != nil
    }
}

struct PetDressUpPreviewGeometry {
    let previewSize: CGSize
    let artworkScale: CGFloat
    let petBaseScale: CGFloat

    private var artworkOrigin: CGPoint {
        CGPoint(
            x: (previewSize.width - OfficialPetArtworkMetrics.frameSize.width) / 2,
            y: (previewSize.height - OfficialPetArtworkMetrics.frameSize.height) / 2
        )
    }

    private var artworkCenter: CGPoint {
        CGPoint(
            x: OfficialPetArtworkMetrics.frameSize.width / 2,
            y: OfficialPetArtworkMetrics.frameSize.height / 2
        )
    }

    private var paddedBodySize: CGFloat {
        PetMetrics.bodyContentSize + PetMetrics.bodyPadding * 2
    }

    private var paddedBodyOrigin: CGPoint {
        CGPoint(
            x: (OfficialPetArtworkMetrics.frameSize.width - paddedBodySize) / 2,
            y: OfficialPetArtworkMetrics.frameSize.height - paddedBodySize
        )
    }

    private var petScaleAnchor: CGPoint {
        CGPoint(x: paddedBodySize / 2, y: paddedBodySize)
    }

    func bodyPoint(forPreviewPoint previewPoint: CGPoint) -> CGPoint {
        var point = CGPoint(
            x: previewPoint.x - artworkOrigin.x,
            y: previewPoint.y - artworkOrigin.y
        )
        point = inverseScale(point, around: artworkCenter, by: artworkScale)
        point.x -= paddedBodyOrigin.x
        point.y -= paddedBodyOrigin.y
        point = inverseScale(point, around: petScaleAnchor, by: petBaseScale)
        point.x -= PetMetrics.bodyPadding
        point.y -= PetMetrics.bodyPadding
        return point
    }

    func previewPoint(forBodyPoint bodyPoint: CGPoint) -> CGPoint {
        var point = CGPoint(
            x: bodyPoint.x + PetMetrics.bodyPadding,
            y: bodyPoint.y + PetMetrics.bodyPadding
        )
        point = scale(point, around: petScaleAnchor, by: petBaseScale)
        point.x += paddedBodyOrigin.x
        point.y += paddedBodyOrigin.y
        point = scale(point, around: artworkCenter, by: artworkScale)
        point.x += artworkOrigin.x
        point.y += artworkOrigin.y
        return point
    }

    private func scale(_ point: CGPoint, around anchor: CGPoint, by factor: CGFloat) -> CGPoint {
        CGPoint(
            x: anchor.x + (point.x - anchor.x) * factor,
            y: anchor.y + (point.y - anchor.y) * factor
        )
    }

    private func inverseScale(
        _ point: CGPoint,
        around anchor: CGPoint,
        by factor: CGFloat
    ) -> CGPoint {
        guard factor != 0 else { return anchor }
        return scale(point, around: anchor, by: 1 / factor)
    }
}

private struct DraggableEquippedDecorationView: View {
    let decoration: PetEquippedDecoration
    let item: PetShopItemDefinition
    let containerSize: CGSize
    let renderedSideLength: CGFloat
    let dragBounds: CGRect
    let gestureScale: CGFloat
    let coordinateSpaceName: String
    let move: (PetDecorationPosition) -> Bool
    let resize: (Double) -> Bool
    let remove: () -> Bool

    @State private var dragOffset = CGSize.zero

    var body: some View {
        PetDecorationArtworkView(item: item)
            .frame(
                width: renderedSideLength,
                height: renderedSideLength
            )
            .background {
                DecorationScrollWheelReader { scrollingDeltaY in
                    let scaleChange = min(max(scrollingDeltaY * 0.04, -0.12), 0.12)
                    _ = resize(scaleChange)
                }
            }
            .contentShape(Rectangle())
            .position(decoration.position.point(in: containerSize))
            .offset(dragOffset)
            .gesture(
                DragGesture(
                    minimumDistance: 2,
                    coordinateSpace: .named(coordinateSpaceName)
                )
                .onChanged { value in
                    dragOffset = bodyOffset(for: value.translation)
                }
                .onEnded { value in
                    if dragBounds.contains(value.location) {
                        let originalPoint = decoration.position.point(in: containerSize)
                        let movedPoint = CGPoint(
                            x: originalPoint.x + dragOffset.width,
                            y: originalPoint.y + dragOffset.height
                        )
                        _ = move(PetDecorationPosition(location: movedPoint, in: containerSize))
                    } else {
                        _ = remove()
                    }
                    dragOffset = .zero
                }
            )
    }

    private func bodyOffset(for previewTranslation: CGSize) -> CGSize {
        guard gestureScale != 0 else { return .zero }
        return CGSize(
            width: previewTranslation.width / gestureScale,
            height: previewTranslation.height / gestureScale
        )
    }
}

private struct PetDressUpWarehouseCard: View {
    let item: PetShopItemDefinition
    let quantity: Int

    var body: some View {
        VStack(spacing: 5) {
            PetDecorationArtworkView(item: item)
                .frame(width: 52, height: 52)
            Text(item.name)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
            Text("数量 \(quantity)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 10))
        .contentShape(RoundedRectangle(cornerRadius: 10))
        .draggable(item.id) {
            PetDecorationArtworkView(item: item)
                .frame(width: 72, height: 72)
        }
    }
}
