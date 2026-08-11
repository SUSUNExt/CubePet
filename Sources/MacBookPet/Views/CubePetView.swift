import SwiftUI

enum CubeSkinAsset {
    static func resourceName(for style: CubeSkinStyle) -> String? {
        switch style {
        case .ice2:
            "CubeSkinIce2"
        case .rainbow2:
            "CubeSkinRainbow2"
        case .solid, .ice, .rainbow:
            nil
        }
    }
}

struct CubePetView: View {
    let color: Color
    let skinStyle: CubeSkinStyle
    let expression: PetExpression
    let isBlinking: Bool
    let gazeOffset: CGSize
    let mouthOpen: CGFloat
    let visualConfiguration: PetVisualConfiguration
    var customEyeAsset: PetImportedVisualAsset? = nil
    var appliesVerticalBaseOffsetInView = true
    var imagePurpose: PetImagePurpose = .fullResolution

    var body: some View {
        ZStack {
            bodyShape
                .offset(renderedBaseOffset)

            if let eyeConfiguration = stateConfiguration.eyes {
                TrackingEyesView(
                    configuration: eatingEyeConfiguration ?? eyeConfiguration,
                    expression: expression,
                    isBlinking: isEating ? false : isBlinking,
                    gazeOffset: isEating ? .zero : gazeOffset,
                    additionalOffset: CGSize(
                        width: 0,
                        height: isEating ? -9 - mouthOpen * 13 : expression.verticalOffset
                    ),
                    customEyeAsset: customEyeAsset,
                    imagePurpose: imagePurpose
                )
                .animation(.spring(response: 0.18, dampingFraction: 0.72), value: mouthOpen)
            }
        }
    }

    private var visualState: PetVisualState {
        isEating ? .eating : PetVisualState(expression: expression)
    }

    private var stateConfiguration: PetStateVisualConfiguration {
        visualConfiguration.configuration(for: visualState)
    }

    private var isEating: Bool {
        mouthOpen > 0.02
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

    private var eatingEyeConfiguration: PetEyeModuleConfiguration? {
        guard isEating, var eyes = stateConfiguration.eyes else { return nil }
        eyes.kind = .eating
        return eyes
    }

    @ViewBuilder
    private var bodyShape: some View {
        if mouthOpen > 0.01 {
            let bodySize = PetMetrics.bodyContentSize
            let lowerHeight = bodySize * 0.34
            let upperHeight = bodySize - lowerHeight
            let gap = 3 + mouthOpen * 17

            ZStack(alignment: .bottom) {
                cubeSegment(width: bodySize, height: lowerHeight)

                cubeSegment(width: bodySize, height: upperHeight)
                    .offset(y: -(lowerHeight + gap))
            }
            .frame(width: bodySize, height: bodySize, alignment: .bottom)
            .animation(.spring(response: 0.18, dampingFraction: 0.72), value: mouthOpen)
        } else {
            cubeSegment(width: nil, height: nil)
        }
    }

    @ViewBuilder
    private func cubeSegment(width: CGFloat?, height: CGFloat?) -> some View {
        let shape = RoundedRectangle(cornerRadius: PetMetrics.cornerRadius, style: .continuous)

        shape
            .fill(bodyFill)
            .frame(width: width, height: height)
            .overlay {
                if let resourceName = CubeSkinAsset.resourceName(for: skinStyle) {
                    PetAssetImageView(
                        url: PetResourceURLCache.url(
                            named: resourceName,
                            withExtension: "png"
                        ),
                        purpose: imagePurpose,
                        contentMode: .fill
                    )
                        // The generated asset has transparent display padding.
                        // This scale aligns its painted cube with the live body shape.
                        .scaleEffect(1.39)
                        .clipShape(shape)
                }

                if skinStyle == .ice {
                    shape
                        .stroke(.white.opacity(0.78), lineWidth: 1.5)
                        .overlay(alignment: .topLeading) {
                            LinearGradient(
                                colors: [.white.opacity(0.75), .white.opacity(0.12), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .clipShape(shape)
                        }
                }
            }
    }

    private var bodyFill: AnyShapeStyle {
        switch skinStyle {
        case .solid:
            AnyShapeStyle(color)
        case .ice:
            AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.32, green: 0.78, blue: 0.96),
                        Color(red: 0.76, green: 0.95, blue: 1),
                        Color(red: 0.24, green: 0.63, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .rainbow:
            AnyShapeStyle(
                LinearGradient(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        case .ice2, .rainbow2:
            // The matching bundled artwork is overlaid in cubeSegment.
            AnyShapeStyle(color)
        }
    }
}
