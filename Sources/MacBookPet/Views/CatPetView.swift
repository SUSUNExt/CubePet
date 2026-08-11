import AppKit
import SwiftUI

@MainActor
enum CatPetAsset {
    static let imageName = "CatPet"
    static let largeMouthImageName = "CatPetMouthLarge"
    static let curledSleepingImageName = "CatPetCurledSleeping"
    static let hungryImageName = "CatPetHungry"
    static let grayTabbyImageName = "CatPetGrayFaceless"
    static let grayTabbyHungryImageName = "CatPetGrayHungry"
    static let grayTabbySleepingImageName = "CatPetGraySleeping"
    static let grayTabbyLargeMouthImageName = "CatPetGrayMouthLarge"
    static let calicoImageName = "CatPetCalicoFaceless"
    static let calicoSleepingImageName = "CatPetCalicoSleeping"
    static let calicoHungryImageName = "CatPetCalicoHungry"
    static let calicoLargeMouthImageName = "CatPetCalicoMouthLarge"
    static let calicoMouthOnlyImageName = "CatPetCalicoMouthOnly"
    static let blackImageName = "CatPetBlackFaceless"
    static let blackSleepingImageName = "CatPetBlackSleeping"
    static let blackHungryImageName = "CatPetBlackHungry"
    static let blackLargeMouthImageName = "CatPetBlackMouthLarge"
    static let siameseImageName = "CatPetSiameseFaceless"
    static let siameseSleepingImageName = "CatPetSiameseSleeping"
    static let siameseHungryImageName = "CatPetSiameseHungry"
    static let siameseMouthImageName = "CatPetSiameseMouthUnique"
    static let yellowImageName = "CatPetYellowFaceless"
    static let yellowHappyImageName = "CatPetYellowHappy"
    static let yellowScaredImageName = "CatPetYellowScared"
    static let yellowSleepingImageName = "CatPetYellowSleeping"
    static let yellowEatingImageName = "CatPetYellowEatingOfficial689cdacb"
    static let yellowHungryImageName = "CatPetYellowHungry"

    static let image = load(named: imageName)
    static let largeMouthImage = load(named: largeMouthImageName)
    static let curledSleepingImage = load(named: curledSleepingImageName)
    static let hungryImage = load(named: hungryImageName)
    static let grayTabbyImage = load(named: grayTabbyImageName)
    static let grayTabbyHungryImage = load(named: grayTabbyHungryImageName)
    static let grayTabbySleepingImage = load(named: grayTabbySleepingImageName)
    static let grayTabbyLargeMouthImage = load(named: grayTabbyLargeMouthImageName)
    static let calicoImage = load(named: calicoImageName)
    static let calicoSleepingImage = load(named: calicoSleepingImageName)
    static let calicoHungryImage = load(named: calicoHungryImageName)
    static let calicoLargeMouthImage = load(named: calicoLargeMouthImageName)
    static let calicoMouthOnlyImage = load(named: calicoMouthOnlyImageName)
    static let blackImage = load(named: blackImageName)
    static let blackSleepingImage = load(named: blackSleepingImageName)
    static let blackHungryImage = load(named: blackHungryImageName)
    static let blackLargeMouthImage = load(named: blackLargeMouthImageName)
    static let siameseImage = load(named: siameseImageName)
    static let siameseSleepingImage = load(named: siameseSleepingImageName)
    static let siameseHungryImage = load(named: siameseHungryImageName)
    static let siameseMouthImage = load(named: siameseMouthImageName)
    static let yellowImage = load(named: yellowImageName)
    static let yellowHappyImage = load(named: yellowHappyImageName)
    static let yellowScaredImage = load(named: yellowScaredImageName)
    static let yellowSleepingImage = load(named: yellowSleepingImageName)
    // This is the user-approved imported eating artwork, promoted to the
    // official Yellow Xiaohuang default.
    static let yellowEatingImage = load(named: yellowEatingImageName)
    static let yellowHungryImage = load(named: yellowHungryImageName)

    private static func load(named name: String) -> NSImage? {
        guard let url = PetResourceURLCache.url(named: name, withExtension: "png") else {
            return nil
        }
        return PetImportedImageCache.image(for: url)
    }
}

struct CatPetImage: View {
    let resourceName: String
    let imagePurpose: PetImagePurpose

    init(
        resourceName: String = "CatPet",
        imagePurpose: PetImagePurpose = .fullResolution
    ) {
        self.resourceName = resourceName
        self.imagePurpose = imagePurpose
    }

    var body: some View {
        PetAssetImageView(
            url: PetResourceURLCache.url(named: resourceName, withExtension: "png"),
            purpose: imagePurpose
        ) {
            Circle()
                .fill(Color(red: 0.94, green: 0.44, blue: 0.08))
                .overlay(
                    VStack(spacing: 2) {
                        HStack(spacing: 7) {
                            Circle().fill(.white).frame(width: 9, height: 9)
                            Circle().fill(.white).frame(width: 9, height: 9)
                        }
                        Capsule(style: .continuous)
                            .fill(Color(red: 0.05, green: 0.16, blue: 0.24))
                            .frame(width: 36, height: 5)
                    }
                    .offset(y: -5)
                )
                .padding(6)
        }
    }
}

struct CatPetView: View {
    let expression: PetExpression
    let isBlinking: Bool
    let gazeOffset: CGSize
    let mouthOpen: CGFloat
    let skinID: String
    let visualConfiguration: PetVisualConfiguration
    var customEyeAsset: PetImportedVisualAsset? = nil
    var appliesVerticalBaseOffsetInView = true
    var imagePurpose: PetImagePurpose = .fullResolution

    var body: some View {
        let isEating = mouthOpen > 0.02
        let defaultEyeScale: CGFloat = !isEating && expression == .calm ? 0.86 : 1
        let defaultEyeOffsetY: CGFloat = !isEating && expression == .calm ? 1.2 : 0
        let eyeBackgroundScale: CGFloat = isBlack ? 0.9 : 1
        let eyeMarkScale: CGFloat = isSiamese && (isEating || !usesWhiteEyeInk)
            ? 0.70
            : eyeBackgroundScale

        return ZStack {
            ZStack {
                CatPetImage(
                    resourceName: catImageResourceName(isEating: false),
                    imagePurpose: imagePurpose
                )
                    .scaleEffect(imageScale, anchor: .bottom)

                if isEating {
                    CatPetImage(
                        resourceName: catImageResourceName(isEating: true),
                        imagePurpose: imagePurpose
                    )
                        .scaleEffect(
                            isGrayTabby || isYellow ? imageScale : (isDefaultSkin ? 0.925 : 1),
                            anchor: .bottom
                        )
                        .offset(
                            x: isDefaultSkin ? 1.6 : 0,
                            y: isDefaultSkin ? -3.2 : 0
                        )
                }
            }
            .transaction { transaction in
                transaction.animation = nil
            }
            .offset(renderedBaseOffset)

            if let eyeConfiguration, let customEyeAsset {
                CustomEyePairView(
                    asset: customEyeAsset,
                    configuration: eyeConfiguration,
                    additionalOffset: CGSize(width: 0, height: defaultEyeOffsetY),
                    imagePurpose: imagePurpose
                )
                .frame(width: PetMetrics.bodyContentSize, height: PetMetrics.bodyContentSize)
                .scaleEffect(isGrayTabby ? 1.08 : 1, anchor: .bottom)
            } else if let eyeConfiguration, !usesBakedEyes(isEating: isEating) {
                CatEyePairView(
                    configuration: eyeConfiguration,
                    expression: expression,
                    isBlinking: isEating ? false : isBlinking,
                    gazeOffset: isEating ? .zero : gazeOffset,
                    additionalOffsetY: defaultEyeOffsetY,
                    allowsEyeWhites: isEating || showsEyeWhites,
                    eyeBackgroundScale: eyeBackgroundScale
                        * defaultEyeScale
                        * CGFloat(eyeConfiguration.resolvedOuterEyeScale),
                    eyeMarkScale: eyeMarkScale
                        * defaultEyeScale
                        * CGFloat(eyeConfiguration.resolvedPupilScale),
                    eyeInk: resolvedEyeInk(isEating: isEating)
                )
                .frame(width: PetMetrics.bodyContentSize, height: PetMetrics.bodyContentSize)
                .scaleEffect(isGrayTabby ? 1.08 : 1, anchor: .bottom)
            }
        }
        .offset(y: isGrayTabby ? 2 : 0)
        .scaleEffect(
            x: 1,
            y: isEating && !isDefaultSkin && !isGrayTabby && !isCalico ? 1.06 : 1,
            anchor: .bottom
        )
    }

    private var isGrayTabby: Bool {
        skinID == "cat.grayTabby"
    }

    private var isCalico: Bool {
        skinID == "cat.calico"
    }

    private var isBlack: Bool {
        skinID == "cat.black"
    }

    private var isSiamese: Bool {
        skinID == "cat.siamese"
    }

    private var isYellow: Bool {
        skinID == "cat.yellow"
    }

    private var imageScale: CGFloat {
        isGrayTabby ? 1.18 : 1
    }

    private var usesBakedEatingEyes: Bool {
        return isGrayTabby || isBlack || isSiamese || isDefaultSkin
    }

    private var usesBakedSleepingEyes: Bool {
        (isDefaultSkin || isGrayTabby || isCalico || isBlack || isSiamese) && expression == .sleeping
    }

    private var usesBakedHungryEyes: Bool {
        (isDefaultSkin || isGrayTabby || isCalico || isBlack || isSiamese) && expression == .hungry
    }

    private var isDefaultSkin: Bool {
        !isGrayTabby && !isCalico && !isBlack && !isSiamese && !isYellow
    }

    private var stateConfiguration: PetStateVisualConfiguration {
        visualConfiguration.configuration(
            for: mouthOpen > 0.02 ? .eating : PetVisualState(expression: expression)
        )
    }

    private var eyeConfiguration: PetEyeModuleConfiguration? {
        // `stateConfiguration` already resolves the eating state while the
        // mouth is open. Keep its selected kind intact so editor changes to
        // the eating-state eye style are reflected on every cat skin.
        stateConfiguration.eyes
    }

    private var renderedBaseOffset: CGSize {
        let offset = stateConfiguration.baseOffset ?? .zero
        return CGSize(
            width: CGFloat(offset.x) * PetMetrics.bodyContentSize,
            height: appliesVerticalBaseOffsetInView
                ? CGFloat(offset.y) * PetMetrics.bodyContentSize
                : 0
        )
    }

    private func catImageResourceName(isEating: Bool) -> String {
        if isYellow {
            if isEating { return CatPetAsset.yellowEatingImageName }
            switch expression {
            case .happy: return CatPetAsset.yellowHappyImageName
            case .scared: return CatPetAsset.yellowScaredImageName
            case .sleeping: return CatPetAsset.yellowSleepingImageName
            case .hungry: return CatPetAsset.yellowHungryImageName
            default: return CatPetAsset.yellowImageName
            }
        }
        if isEating {
            if isGrayTabby { return CatPetAsset.grayTabbyLargeMouthImageName }
            if isCalico { return CatPetAsset.calicoMouthOnlyImageName }
            if isBlack { return CatPetAsset.blackLargeMouthImageName }
            if isSiamese { return CatPetAsset.siameseMouthImageName }
            return CatPetAsset.largeMouthImageName
        }
        if usesBakedSleepingEyes {
            if isGrayTabby { return CatPetAsset.grayTabbySleepingImageName }
            if isCalico { return CatPetAsset.calicoSleepingImageName }
            if isBlack { return CatPetAsset.blackSleepingImageName }
            if isSiamese { return CatPetAsset.siameseSleepingImageName }
            return CatPetAsset.curledSleepingImageName
        }
        if !isCurrentlyEating && usesBakedHungryEyes {
            if isGrayTabby { return CatPetAsset.grayTabbyHungryImageName }
            if isCalico { return CatPetAsset.calicoHungryImageName }
            if isBlack { return CatPetAsset.blackHungryImageName }
            if isSiamese { return CatPetAsset.siameseHungryImageName }
            return CatPetAsset.hungryImageName
        }
        if isGrayTabby { return CatPetAsset.grayTabbyImageName }
        if isCalico { return CatPetAsset.calicoImageName }
        if isBlack { return CatPetAsset.blackImageName }
        if isSiamese { return CatPetAsset.siameseImageName }
        return CatPetAsset.imageName
    }

    private func usesBakedEyes(isEating: Bool) -> Bool {
        isYellow || (isEating && usesBakedEatingEyes) || usesBakedSleepingEyes || (!isEating && usesBakedHungryEyes)
    }

    private var isCurrentlyEating: Bool {
        mouthOpen > 0.02
    }

    private var showsEyeWhites: Bool {
        switch expression {
        case .calm, .curious:
            return true
        default:
            return false
        }
    }

    private var automaticEyeInk: Color {
        guard isBlack || isSiamese else {
            return Color(red: 0.08, green: 0.055, blue: 0.035)
        }

        switch expression {
        case .happy, .scared, .sleeping:
            return .white
        default:
            return Color(red: 0.08, green: 0.055, blue: 0.035)
        }
    }

    private func resolvedEyeInk(isEating: Bool) -> Color {
        switch stateConfiguration.eyes?.resolvedColorMode ?? .automatic {
        case .black:
            return .black
        case .white:
            return .white
        case .brown:
            return Color(red: 112.0 / 255.0, green: 68.0 / 255.0, blue: 41.0 / 255.0)
        case .automatic:
            return isEating
                ? Color(red: 0.08, green: 0.055, blue: 0.035)
                : automaticEyeInk
        }
    }

    private var usesWhiteEyeInk: Bool {
        switch stateConfiguration.eyes?.resolvedColorMode ?? .automatic {
        case .black:
            return false
        case .white:
            return true
        case .brown:
            return false
        case .automatic:
            break
        }

        guard isBlack || isSiamese else { return false }

        switch expression {
        case .happy, .scared, .sleeping:
            return true
        default:
            return false
        }
    }
}

private struct CatEyePairView: View {
    let configuration: PetEyeModuleConfiguration
    let expression: PetExpression
    let isBlinking: Bool
    let gazeOffset: CGSize
    let additionalOffsetY: CGFloat
    let allowsEyeWhites: Bool
    let eyeBackgroundScale: CGFloat
    let eyeMarkScale: CGFloat
    let eyeInk: Color

    var body: some View {
        EyePairLayout(
            configuration: configuration,
            additionalOffset: CGSize(width: 0, height: additionalOffsetY)
        ) {
            catEye(style: eyeStyles.left, isLeft: true)
        } rightEye: {
            catEye(style: eyeStyles.right, isLeft: false)
        }
    }

    private var eyeStyles: (left: EyeStyle, right: EyeStyle) {
        configuration.eyeStyles(for: expression)
    }

    private var effectiveBlinking: Bool {
        configuration.allowsBlinking && isBlinking
    }

    private var showsEyeWhites: Bool {
        guard allowsEyeWhites else { return false }
        return usesEyeWhites(for: eyeStyles.left) && usesEyeWhites(for: eyeStyles.right)
    }

    private var effectiveGaze: CGSize {
        guard configuration.followsMouse(for: expression) else { return .zero }
        let scale = CGFloat(configuration.resolvedPupilGazeScale)
        return CGSize(
            width: gazeOffset.width * 0.44 * scale,
            height: gazeOffset.height * 0.44 * scale
        )
    }

    private func catEye(style: EyeStyle, isLeft: Bool) -> some View {
        ZStack {
            if showsEyeWhites {
                Circle()
                    .fill(.white)
                    .frame(width: 9.2, height: 9.2)
                    .scaleEffect(eyeBackgroundScale)
            }

            CatEyeMark(
                style: style,
                isBlinking: effectiveBlinking,
                ink: eyeInk
            )
            .scaleEffect(eyeMarkScale)
            .offset(
                x: effectiveGaze.width + pupilOffsetX(isLeft: isLeft),
                y: effectiveGaze.height
            )
            .animation(.easeOut(duration: 0.10), value: gazeOffset)
        }
        .frame(width: 14, height: 14)
    }

    private func pupilOffsetX(isLeft: Bool) -> CGFloat {
        guard showsEyeWhites, !effectiveBlinking else { return 0 }
        let spacing = CGFloat(configuration.resolvedPupilSpacing)
        return isLeft ? -spacing : spacing
    }

    private func usesEyeWhites(for style: EyeStyle) -> Bool {
        switch style {
        case .round, .largeRound, .smallRound:
            true
        case .smile, .invertedSmile, .sleepy, .annoyedLeft, .annoyedRight,
             .chevronLeft, .chevronRight:
            false
        }
    }
}

private struct CatEyeMark: View {
    let style: EyeStyle
    let isBlinking: Bool
    let ink: Color

    var body: some View {
        Group {
            if isBlinking {
                Capsule(style: .continuous)
                    .fill(ink)
                    .frame(width: 9, height: 2)
            } else {
                eyeShape
            }
        }
        .frame(width: 14, height: 14)
    }

    @ViewBuilder
    private var eyeShape: some View {
        switch style {
        case .round:
            Circle().fill(ink).frame(width: 5.6, height: 5.6)
        case .largeRound:
            Circle().fill(ink).frame(width: 6.8, height: 6.8)
        case .smallRound:
            Circle().fill(ink).frame(width: 4.1, height: 4.1)
        case .smile:
            CatArcEye(isInverted: false)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 8, height: 6)
        case .invertedSmile:
            CatArcEye(isInverted: true)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                .frame(width: 8, height: 6)
        case .sleepy:
            Capsule(style: .continuous).fill(ink).frame(width: 9, height: 2)
        case .annoyedLeft:
            Capsule(style: .continuous).fill(ink).frame(width: 9, height: 2).rotationEffect(.degrees(14))
        case .annoyedRight:
            Capsule(style: .continuous).fill(ink).frame(width: 9, height: 2).rotationEffect(.degrees(-14))
        case .chevronLeft:
            CatChevronEye(opensLeft: true)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: 8, height: 9)
        case .chevronRight:
            CatChevronEye(opensLeft: false)
                .stroke(ink, style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))
                .frame(width: 8, height: 9)
        }
    }

}

private struct CatArcEye: Shape {
    let isInverted: Bool

    func path(in rect: CGRect) -> Path {
        let controlY = isInverted ? rect.maxY + 2 : rect.minY - 2
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 1, y: rect.midY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - 1, y: rect.midY),
            control: CGPoint(x: rect.midX, y: controlY)
        )
        return path
    }
}

private struct CatChevronEye: Shape {
    let opensLeft: Bool

    func path(in rect: CGRect) -> Path {
        let tipX = opensLeft ? rect.minX + 1 : rect.maxX - 1
        let openX = opensLeft ? rect.maxX - 1 : rect.minX + 1
        var path = Path()
        path.move(to: CGPoint(x: openX, y: rect.minY + 1))
        path.addLine(to: CGPoint(x: tipX, y: rect.midY))
        path.addLine(to: CGPoint(x: openX, y: rect.maxY - 1))
        return path
    }
}
