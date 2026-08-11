import AppKit
import SwiftUI

enum PetDecorationRenderingMetrics {
    static let relativeWidth: CGFloat = 0.72

    static func sideLength(decorationScale: Double) -> CGFloat {
        PetMetrics.bodyContentSize
            * relativeWidth
            * CGFloat(PetEquippedDecoration.clampedScale(decorationScale))
    }
}

struct PetDecorationArtworkView: View {
    let item: PetShopItemDefinition

    var body: some View {
        Group {
            if case let .asset(resourceName) = item.icon {
                PetAssetImageView(
                    url: PetResourceURLCache.url(named: resourceName, withExtension: nil),
                    purpose: .fullResolution
                ) {
                    Image(systemName: "photo")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityLabel(item.name)
    }
}
