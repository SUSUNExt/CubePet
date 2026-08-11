import AppKit
import SwiftUI

struct MyPetsView: View {
    static let thumbnailMaxPixelSize = 320

    @ObservedObject var progressStore: PetProgressStore
    @ObservedObject var inventoryStore: PetInventoryStore
    @ObservedObject var languageSettings: LanguageSettings

    @State private var selectedPetSkinID: String?
    @State private var isDecorationPanelPresented = false

    private let columns = [
        GridItem(.adaptive(minimum: 210, maximum: 240), spacing: 18)
    ]

    private var ownedPetSkins: [MyPetSkin] {
        MyPetsCatalog.ownedPetSkins(
            ownedPetIDs: progressStore.ownedPetIDs,
            ownedSkinIDs: progressStore.ownedSkinIDs
        )
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    guard isDecorationPanelPresented else { return }
                    dismissDecorationPanel()
                }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(ownedPetSkins) { petSkin in
                        if let pet = PetCatalog.pet(id: petSkin.petID),
                           let skin = pet.skin(id: petSkin.skinID) {
                            MyPetCollectionCard(
                                pet: pet,
                                skin: skin,
                                chineseName: languageSettings.skinName(
                                    skin.name,
                                    language: .simplifiedChinese
                                ),
                                englishName: languageSettings.skinName(
                                    skin.name,
                                    language: .english
                                ),
                                isSelected: selectedPetSkinID == petSkin.id
                            ) {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    selectedPetSkinID = petSkin.id
                                    isDecorationPanelPresented = true
                                }
                            }
                            .accessibilityAddTraits(
                                selectedPetSkinID == petSkin.id ? .isSelected : []
                            )
                        }
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, isDecorationPanelPresented ? 342 : 22)
            }

            if isDecorationPanelPresented {
                decorationPanel
                    .zIndex(1)
            }
        }
        .onChange(of: ownedPetSkins) { _, newValue in
            guard let selectedPetSkinID else { return }
            if !newValue.contains(where: { $0.id == selectedPetSkinID }) {
                self.selectedPetSkinID = nil
                isDecorationPanelPresented = false
            }
        }
        .onDisappear {
            PetListThumbnailCache.removeAll()
        }
    }

    @ViewBuilder
    private var decorationPanel: some View {
        if let selectedPetSkin = ownedPetSkins.first(where: { $0.id == selectedPetSkinID }),
           let pet = PetCatalog.pet(id: selectedPetSkin.petID),
           let skin = pet.skin(id: selectedPetSkin.skinID) {
            PetDressUpPanel(
                pet: pet,
                skin: skin,
                inventoryStore: inventoryStore,
                dismiss: dismissDecorationPanel
            )
            .frame(maxWidth: .infinity)
            .frame(height: 320)
            .transition(.move(edge: .bottom))
        }
    }

    private func dismissDecorationPanel() {
        withAnimation(.easeOut(duration: 0.2)) {
            isDecorationPanelPresented = false
        }
    }

}

private struct MyPetCollectionCard: View {
    let pet: PetDefinition
    let skin: PetSkinDefinition
    let chineseName: String
    let englishName: String
    let isSelected: Bool
    let select: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: select) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height

                ZStack {
                    cardBackground

                    HStack(spacing: width * 0.014) {
                        Image(systemName: "pawprint.fill")
                        Text(chineseName)
                            .font(
                                .system(
                                    size: width * 0.074,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .lineLimit(1)
                            .minimumScaleFactor(0.68)
                        Image(systemName: "pawprint.fill")
                    }
                    .font(.system(size: width * 0.032, weight: .bold))
                    .foregroundStyle(Color(red: 0.34, green: 0.21, blue: 0.11))
                    .frame(width: width * 0.47)
                    .position(x: width * 0.50, y: height * 0.115)

                    Text(englishName.uppercased())
                        .font(
                            .system(
                                size: width * 0.032,
                                weight: .bold,
                                design: .rounded
                            )
                        )
                        .tracking(width * 0.002)
                        .foregroundStyle(Color(red: 1.0, green: 0.93, blue: 0.80))
                        .lineLimit(1)
                        .minimumScaleFactor(0.50)
                        .allowsTightening(true)
                        .frame(width: width * 0.21)
                        .position(x: width * 0.50, y: height * 0.176)

                    OfficialPetArtworkView(
                        pet: pet,
                        skin: skin,
                        imagePurpose: .listThumbnail(
                            maxPixelSize: MyPetsView.thumbnailMaxPixelSize
                        )
                    )
                        .scaleEffect(min(1.65, max(1.20, width / 160)))
                        .position(x: width * 0.50, y: height * 0.56)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovering ? 1.018 : 1)
        .shadow(
            color: .black.opacity(isHovering ? 0.20 : 0.10),
            radius: isHovering ? 10 : 5,
            x: 0,
            y: isHovering ? 6 : 3
        )
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.accentColor.opacity(0.75), lineWidth: 3)
                    .padding(6)
                    .allowsHitTesting(false)
            }
        }
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.16), value: isHovering)
        .accessibilityLabel("\(chineseName)，\(englishName)")
        .accessibilityHint("点击打扮宠物")
    }

    @ViewBuilder
    private var cardBackground: some View {
        PetAssetImageView(
            url: PetResourceURLCache.url(
                named: "MyPetsCollectionCard",
                withExtension: "png"
            ),
            purpose: .listThumbnail(maxPixelSize: 512)
        ) {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color(red: 1.0, green: 0.96, blue: 0.89))
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.brown.opacity(0.45), lineWidth: 2)
                }
        }
    }
}

/// Renders the official normal-state body with the same pet-specific views and
/// `PetVisualDefaults` configuration used by the desktop pet. Saved editor
/// overrides are intentionally excluded from this collection view.
enum OfficialPetArtworkMetrics {
    static let frameSize = CGSize(width: 92, height: 82)
}

struct OfficialPetArtworkView<Accessory: View>: View {
    let pet: PetDefinition
    let skin: PetSkinDefinition
    let imagePurpose: PetImagePurpose
    let accessory: Accessory

    init(
        pet: PetDefinition,
        skin: PetSkinDefinition,
        imagePurpose: PetImagePurpose = .fullResolution,
        @ViewBuilder accessory: () -> Accessory
    ) {
        self.pet = pet
        self.skin = skin
        self.imagePurpose = imagePurpose
        self.accessory = accessory()
    }

    private var visualConfiguration: PetVisualConfiguration {
        PetVisualDefaults.configuration(petID: pet.id, skinID: skin.id)
    }

    private var stateConfiguration: PetStateVisualConfiguration {
        visualConfiguration.configuration(for: .normal)
    }

    var body: some View {
        ZStack {
            officialBody
            accessory
        }
            .frame(width: PetMetrics.bodyContentSize, height: PetMetrics.bodyContentSize)
            .padding(PetMetrics.bodyPadding)
            .scaleEffect(
                CGFloat(stateConfiguration.resolvedBaseScale),
                anchor: .bottom
            )
            .frame(
                width: OfficialPetArtworkMetrics.frameSize.width,
                height: OfficialPetArtworkMetrics.frameSize.height,
                alignment: .bottom
            )
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var officialBody: some View {
        if case let .bundledAsset(name) = stateConfiguration.base {
            ImportedPetVisualView(
                asset: bundledVisualAsset(named: name),
                baseOffset: stateConfiguration.baseOffset,
                animationPlaybackRate: stateConfiguration.animationPlaybackRate,
                playsAnimation: false,
                imagePurpose: imagePurpose,
                configuration: stateConfiguration.eyes,
                expression: .calm,
                isBlinking: false,
                gazeOffset: .zero
            )
        } else {
            switch pet.visualKind {
            case .cube, .cookie:
                CubePetView(
                    color: Color(nsColor: skin.color),
                    skinStyle: CubeSkinStyle(skinID: skin.id),
                    expression: .calm,
                    isBlinking: false,
                    gazeOffset: .zero,
                    mouthOpen: 0,
                    visualConfiguration: visualConfiguration,
                    imagePurpose: imagePurpose
                )
            case .frog:
                FrogPetView(
                    expression: .calm,
                    isBlinking: false,
                    gazeOffset: .zero,
                    mouthOpen: 0,
                    visualConfiguration: visualConfiguration,
                    imagePurpose: imagePurpose
                )
            case .cat:
                CatPetView(
                    expression: .calm,
                    isBlinking: false,
                    gazeOffset: .zero,
                    mouthOpen: 0,
                    skinID: skin.id,
                    visualConfiguration: visualConfiguration,
                    imagePurpose: imagePurpose
                )
            case .dog:
                Image(systemName: "dog.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.brown)
                    .padding(12)
            }
        }
    }

    private func bundledVisualAsset(named name: String) -> PetImportedVisualAsset? {
        PetBundledVisualAssetCache.visualAsset(named: name)
    }
}

extension OfficialPetArtworkView where Accessory == EmptyView {
    init(
        pet: PetDefinition,
        skin: PetSkinDefinition,
        imagePurpose: PetImagePurpose = .fullResolution
    ) {
        self.init(pet: pet, skin: skin, imagePurpose: imagePurpose) {
            EmptyView()
        }
    }
}
