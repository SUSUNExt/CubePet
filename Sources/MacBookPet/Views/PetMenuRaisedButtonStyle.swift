import AppKit
import SwiftUI

private enum PetMenuRaisedButtonPalette {
    static let text = Color(red: 56 / 255, green: 43 / 255, blue: 34 / 255)
    static let face = Color(red: 1, green: 240 / 255, blue: 240 / 255)
}

@MainActor
private enum PetMenuRaisedButtonArtwork {
    static let image: NSImage? = {
        guard let url = PetResourceURLCache.url(
            named: "PetMenuHandDrawnButton",
            withExtension: "png"
        ) else {
            return nil
        }
        return PetImportedImageCache.image(for: url)
    }()
}

struct PetMenuRaisedButtonStyle: ButtonStyle {
    var isSelected = false
    var isCompact = false

    func makeBody(configuration: Configuration) -> some View {
        PetMenuRaisedButtonBody(
            configuration: configuration,
            isSelected: isSelected,
            isCompact: isCompact
        )
    }
}

private struct PetMenuRaisedButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let isSelected: Bool
    let isCompact: Bool

    @State private var isHovering = false

    private let animation = Animation.easeOut(duration: 0.14)

    private let em: CGFloat = 15

    var body: some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(PetMenuRaisedButtonPalette.text)
            .lineLimit(1)
            .padding(.vertical, isCompact ? em * 0.60 : em * 1.10)
            .padding(.horizontal, isCompact ? em * 0.75 : em * 2)
            .background {
                buttonArtwork
            }
            .brightness(brightness)
            .saturation(isSelected ? 1.08 : 1)
            .scaleEffect(configuration.isPressed ? 0.975 : isHovering ? 1.01 : 1)
            .offset(y: configuration.isPressed ? 2 : isSelected ? 1 : 0)
            .padding(.vertical, 3)
            .contentShape(Rectangle())
            .onHover { isHovering = $0 }
            .animation(animation, value: isHovering)
            .animation(animation, value: isSelected)
            .animation(animation, value: configuration.isPressed)
    }

    @ViewBuilder
    private var buttonArtwork: some View {
        if let image = PetMenuRaisedButtonArtwork.image {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
        } else {
            RoundedRectangle(cornerRadius: em * 0.75, style: .continuous)
                .fill(PetMenuRaisedButtonPalette.face)
        }
    }

    private var brightness: Double {
        if configuration.isPressed { return -0.035 }
        if isSelected { return -0.018 }
        return isHovering ? 0.025 : 0
    }
}
