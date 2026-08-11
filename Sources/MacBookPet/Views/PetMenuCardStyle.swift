import AppKit
import SwiftUI

enum PetMenuCardPalette {
    static let bisque = Color(red: 1, green: 228 / 255, blue: 196 / 255)
    static let blush = Color(red: 1, green: 231 / 255, blue: 222 / 255)
    static let softCoral = Color(red: 1, green: 211 / 255, blue: 195 / 255)
    static let coral = Color(red: 1, green: 127 / 255, blue: 80 / 255)
    static let cocoa = Color(red: 79 / 255, green: 58 / 255, blue: 42 / 255)
}

@MainActor
private enum PetMenuCardArtwork {
    static let image: NSImage? = {
        guard let url = PetResourceURLCache.url(
            named: "PetMenuHandDrawnCard",
            withExtension: "png"
        ) else {
            return nil
        }
        return PetImportedImageCache.image(for: url)
    }()
}

struct PetMenuCardButtonStyle: ButtonStyle {
    let isHovering: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .petMenuCardSurface(
                isHovering: isHovering,
                isPressed: configuration.isPressed
            )
    }
}

private struct PetMenuCardSurfaceModifier: ViewModifier {
    let isHovering: Bool
    let isPressed: Bool

    private let cornerRadius: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .foregroundStyle(PetMenuCardPalette.cocoa)
            .background {
                cardArtwork
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .brightness(isHovering && !isPressed ? 0.025 : 0)
            .scaleEffect(isPressed ? 0.975 : isHovering ? 1.012 : 1)
            .offset(y: verticalOffset)
            .animation(.easeOut(duration: 0.16), value: isHovering)
            .animation(.easeOut(duration: 0.08), value: isPressed)
    }

    @ViewBuilder
    private var cardArtwork: some View {
        if let image = PetMenuCardArtwork.image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(PetMenuCardPalette.bisque)
        }
    }

    private var verticalOffset: CGFloat {
        if isPressed { return 2 }
        return isHovering ? -2 : 0
    }
}

extension View {
    func petMenuCardSurface(isHovering: Bool, isPressed: Bool = false) -> some View {
        modifier(
            PetMenuCardSurfaceModifier(
                isHovering: isHovering,
                isPressed: isPressed
            )
        )
    }

}

struct PetMenuCardPriceBadge: View {
    let price: Int

    var body: some View {
        Text("\(price)G")
            .font(.caption.weight(.semibold))
            .foregroundStyle(PetMenuCardPalette.cocoa.opacity(0.82))
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(PetMenuCardPalette.softCoral.opacity(0.44), in: Capsule())
    }
}

struct PetMenuCardHoverActionLabel: View {
    let title: String
    let isVisible: Bool
    var isEnabled = true

    var body: some View {
        Text(title)
            .font(.callout.weight(.semibold))
            .foregroundStyle(
                isEnabled
                    ? PetMenuCardPalette.coral
                    : PetMenuCardPalette.coral.opacity(0.45)
            )
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 4)
            .animation(.easeOut(duration: 0.18), value: isVisible)
    }
}
