import AppKit
import SwiftUI

struct TrackingEyesView: View {
    let configuration: PetEyeModuleConfiguration
    let expression: PetExpression
    let isBlinking: Bool
    let gazeOffset: CGSize
    var additionalOffset: CGSize = .zero
    var customEyeAsset: PetImportedVisualAsset? = nil
    var imagePurpose: PetImagePurpose = .fullResolution

    var body: some View {
        Group {
            if let customEyeAsset {
                CustomEyePairView(
                    asset: customEyeAsset,
                    configuration: configuration,
                    additionalOffset: CGSize(
                        width: effectiveGaze.width + additionalOffset.width,
                        height: effectiveGaze.height + additionalOffset.height
                    ),
                    imagePurpose: imagePurpose
                )
            } else if configuration.kind == .shibaWatercolor {
                ShibaWatercolorEyePairView(
                    configuration: configuration,
                    isBlinking: effectiveBlinking,
                    additionalOffset: additionalOffset,
                    imagePurpose: imagePurpose
                )
            } else if configuration.kind == .cookieBlackBean {
                CookieBlackBeanEyePairView(
                    configuration: configuration,
                    additionalOffset: CGSize(
                        width: effectivePupilGaze.width + additionalOffset.width,
                        height: effectivePupilGaze.height + additionalOffset.height
                    ),
                    imagePurpose: imagePurpose
                )
            } else if configuration.kind == .catDefault {
                DefaultCatEyePairView(
                    configuration: configuration,
                    isBlinking: effectiveBlinking,
                    gazeOffset: effectivePupilGaze,
                    additionalOffset: additionalOffset
                )
            } else {
                let gaze = configuration.usesSingleColorEyeControls
                    ? effectivePupilGaze
                    : effectiveGaze
                EyePairLayout(
                    configuration: configuration,
                    additionalOffset: CGSize(
                        width: gaze.width + additionalOffset.width,
                        height: gaze.height + additionalOffset.height
                    )
                ) {
                    EyeView(
                        style: eyeStyles.left,
                        isBlinking: effectiveBlinking,
                        color: eyeColor
                    )
                    .scaleEffect(eyeLayerScale)
                } rightEye: {
                    EyeView(
                        style: eyeStyles.right,
                        isBlinking: effectiveBlinking,
                        color: eyeColor
                    )
                    .scaleEffect(eyeLayerScale)
                }
            }
        }
        .animation(.easeOut(duration: 0.10), value: gazeOffset)
    }

    private var eyeStyles: (left: EyeStyle, right: EyeStyle) {
        configuration.eyeStyles(for: expression)
    }

    private var effectiveBlinking: Bool {
        configuration.allowsBlinking && isBlinking
    }

    private var effectiveGaze: CGSize {
        configuration.followsMouse(for: expression) ? gazeOffset : .zero
    }

    private var effectivePupilGaze: CGSize {
        let scale = CGFloat(configuration.resolvedPupilGazeScale)
        return CGSize(width: effectiveGaze.width * scale, height: effectiveGaze.height * scale)
    }

    private var eyeColor: Color {
        if configuration.usesFixedBlackColor {
            return .black
        }

        return switch configuration.resolvedColorMode {
        case .automatic, .white: .white
        case .black: .black
        case .brown: Color(red: 112.0 / 255.0, green: 68.0 / 255.0, blue: 41.0 / 255.0)
        }
    }

    private var eyeLayerScale: CGFloat {
        if configuration.usesSingleColorEyeControls || configuration.supportsEyeColorSelection {
            return CGFloat(configuration.resolvedOuterEyeScale)
        }

        if configuration.usesFixedBlackColor {
            return CGFloat(configuration.resolvedOuterEyeScale)
        }

        return switch configuration.resolvedColorMode {
        case .black:
            CGFloat(configuration.resolvedPupilScale)
        case .automatic, .white, .brown:
            CGFloat(configuration.resolvedOuterEyeScale)
        }
    }
}

/// Shiba's supplied eye art includes a dedicated closed-eye frame for blinks.
private struct ShibaWatercolorEyePairView: View {
    let configuration: PetEyeModuleConfiguration
    let isBlinking: Bool
    let additionalOffset: CGSize
    let imagePurpose: PetImagePurpose

    var body: some View {
        EyePairLayout(configuration: configuration, additionalOffset: additionalOffset) {
            eyeImage(isMirrored: false)
        } rightEye: {
            eyeImage(isMirrored: true)
        }
    }

    private func eyeImage(isMirrored: Bool) -> some View {
        PetAssetImageView(
            url: PetResourceURLCache.url(
                named: isBlinking
                    ? "ShibaInuWatercolorEyeClosed"
                    : "ShibaInuWatercolorEyeOpen",
                withExtension: "png"
            ),
            purpose: imagePurpose
        ) {
                Image(systemName: "eye").foregroundStyle(.secondary)
        }
        .frame(width: 18, height: 18)
        .scaleEffect(x: isMirrored ? -1 : 1, y: 1)
        .scaleEffect(CGFloat(configuration.resolvedPupilScale))
        .animation(.easeInOut(duration: 0.10), value: isBlinking)
    }
}

/// The reusable single-eye module from Little Cookie. `EyePairLayout` renders
/// this one transparent asset twice, keeping the eye resource independently selectable.
private struct CookieBlackBeanEyePairView: View {
    let configuration: PetEyeModuleConfiguration
    let additionalOffset: CGSize
    let imagePurpose: PetImagePurpose

    var body: some View {
        EyePairLayout(configuration: configuration, additionalOffset: additionalOffset) {
            eyeImage
        } rightEye: {
            eyeImage
        }
    }

    private var eyeImage: some View {
        PetAssetImageView(
            url: PetResourceURLCache.url(
                named: "CookieBlackBeanEye",
                withExtension: "png"
            ),
            purpose: imagePurpose
        ) {
                Image(systemName: "eye")
                    .foregroundStyle(.secondary)
        }
        .frame(width: 16, height: 16)
        .scaleEffect(CGFloat(configuration.resolvedPupilScale))
    }
}

/// The cat's standard wide eyes, available to imported custom pets as a reusable module.
private struct DefaultCatEyePairView: View {
    let configuration: PetEyeModuleConfiguration
    let isBlinking: Bool
    let gazeOffset: CGSize
    let additionalOffset: CGSize

    var body: some View {
        EyePairLayout(configuration: configuration, additionalOffset: additionalOffset) {
            catEye(isLeft: true)
        } rightEye: {
            catEye(isLeft: false)
        }
    }

    private func catEye(isLeft: Bool) -> some View {
        ZStack {
            Circle()
                .fill(.white)
                .frame(width: 9.2, height: 9.2)
                .scaleEffect(CGFloat(configuration.resolvedOuterEyeScale))

            if isBlinking {
                Capsule(style: .continuous)
                    .fill(.black)
                    .frame(width: 9, height: 2)
            } else {
                Circle()
                    .fill(.black)
                    .frame(width: 5.6, height: 5.6)
                    .scaleEffect(CGFloat(configuration.resolvedPupilScale))
                    .offset(
                        x: gazeOffset.width + pupilOffsetX(isLeft: isLeft),
                        y: gazeOffset.height
                    )
                    .animation(.easeOut(duration: 0.10), value: gazeOffset)
            }
        }
        .frame(width: 14, height: 14)
    }

    private func pupilOffsetX(isLeft: Bool) -> CGFloat {
        let spacing = CGFloat(configuration.resolvedPupilSpacing)
        return isLeft ? -spacing : spacing
    }
}

struct CustomEyePairView: View {
    let asset: PetImportedVisualAsset
    let configuration: PetEyeModuleConfiguration
    var additionalOffset: CGSize = .zero
    var imagePurpose: PetImagePurpose = .fullResolution

    var body: some View {
        EyePairLayout(configuration: configuration, additionalOffset: additionalOffset) {
            eyeImage
        } rightEye: {
            eyeImage
        }
    }

    private var eyeImage: some View {
        PetAssetImageView(url: asset.imageURL, purpose: imagePurpose) {
                Image(systemName: "eye")
                    .foregroundStyle(.secondary)
        }
        .frame(width: 16, height: 16)
        .scaleEffect(CGFloat(configuration.resolvedPupilScale))
    }
}

struct EyePairLayout<LeftEye: View, RightEye: View>: View {
    let configuration: PetEyeModuleConfiguration
    let additionalOffset: CGSize
    let leftEye: LeftEye
    let rightEye: RightEye

    init(
        configuration: PetEyeModuleConfiguration,
        additionalOffset: CGSize = .zero,
        @ViewBuilder leftEye: () -> LeftEye,
        @ViewBuilder rightEye: () -> RightEye
    ) {
        self.configuration = configuration
        self.additionalOffset = additionalOffset
        self.leftEye = leftEye()
        self.rightEye = rightEye()
    }

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: spacing) {
                leftEye
                    .offset(eyeOffset(configuration.leftEyeOffset, in: geometry.size))
                rightEye
                    .offset(
                        eyeOffset(configuration.rightEyeOffset, in: geometry.size)
                            + CGSize(width: 0, height: rightEyeOffsetY)
                    )
            }
            .scaleEffect(scale)
            .position(
                x: clampedCenterX * geometry.size.width + additionalOffset.width,
                y: clampedCenterY * geometry.size.height + additionalOffset.height
            )
        }
    }

    private var clampedCenterX: CGFloat {
        CGFloat(min(max(configuration.center.x, 0), 1))
    }

    private var clampedCenterY: CGFloat {
        CGFloat(min(max(configuration.center.y, 0), 1))
    }

    private var scale: CGFloat {
        CGFloat(min(max(configuration.scale, 0.25), 4))
    }

    private var spacing: CGFloat {
        CGFloat(min(max(configuration.spacing, -20), 80))
    }

    private var rightEyeOffsetY: CGFloat {
        CGFloat(min(max(configuration.rightEyeOffsetY ?? 0, -40), 40))
    }

    private func eyeOffset(
        _ normalizedOffset: NormalizedVisualOffset?,
        in size: CGSize
    ) -> CGSize {
        guard let normalizedOffset else { return .zero }
        return CGSize(
            width: CGFloat(normalizedOffset.x) * size.width / scale,
            height: CGFloat(normalizedOffset.y) * size.height / scale
        )
    }
}

private func + (lhs: CGSize, rhs: CGSize) -> CGSize {
    CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
}
