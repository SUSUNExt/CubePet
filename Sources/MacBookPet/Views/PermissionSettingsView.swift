import AppKit
import Combine
import SwiftUI

struct PermissionSettingsView: View {
    @ObservedObject var languageSettings: LanguageSettings
    let isInputMonitoringAllowed: () -> Bool
    let openInputMonitoringSettings: () -> Void
    let openAutomationSettings: () -> Void
    let onClose: () -> Void

    @State private var inputMonitoringAllowed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(languageSettings.permissionSettingsText(.title))
                    .font(.title3.weight(.semibold))
                Text(languageSettings.permissionSettingsText(.description))
                    .foregroundStyle(.secondary)
            }

            PermissionSection(
                icon: "keyboard",
                title: languageSettings.permissionSettingsText(.inputMonitoringTitle),
                description: languageSettings.permissionSettingsText(.inputMonitoringDescription),
                status: inputMonitoringAllowed
                    ? languageSettings.permissionSettingsText(.allowed)
                    : languageSettings.permissionSettingsText(.notAllowed),
                isAllowed: inputMonitoringAllowed,
                actionTitle: languageSettings.permissionSettingsText(.openInputMonitoringSettings),
                action: openInputMonitoringSettings
            )

            PermissionGroup(
                icon: "music.note.list",
                title: languageSettings.permissionSettingsText(.musicPermissionsTitle),
                description: languageSettings.permissionSettingsText(.musicPermissionsDescription)
            ) {
                PermissionSection(
                    icon: "apple.logo",
                    title: languageSettings.permissionSettingsText(.automationTitle),
                    description: languageSettings.permissionSettingsText(.automationDescription),
                    detail: languageSettings.permissionSettingsText(.automationHint),
                    actionTitle: languageSettings.permissionSettingsText(.openAutomationSettings),
                    action: openAutomationSettings,
                    usesCardBackground: false
                )

                MusicAppPermissionRow(
                    iconResourceName: "NetEaseMusicPermissionIcon",
                    title: languageSettings.permissionSettingsText(.neteaseMusicTitle),
                    description: languageSettings.permissionSettingsText(.musicPlaybackDescription),
                    detail: languageSettings.permissionSettingsText(.thirdPartyMusicAutomationHint),
                    actionTitle: languageSettings.permissionSettingsText(.openAutomationSettings),
                    action: openAutomationSettings
                )

                MusicAppPermissionRow(
                    iconResourceName: "QQMusicPermissionIcon",
                    title: languageSettings.permissionSettingsText(.qqMusicTitle),
                    description: languageSettings.permissionSettingsText(.musicPlaybackDescription),
                    detail: languageSettings.permissionSettingsText(.thirdPartyMusicAutomationHint),
                    actionTitle: languageSettings.permissionSettingsText(.openAutomationSettings),
                    action: openAutomationSettings
                )

                MusicAppPermissionRow(
                    iconResourceName: "KuGouMusicPermissionIcon",
                    title: languageSettings.permissionSettingsText(.kugouMusicTitle),
                    description: languageSettings.permissionSettingsText(.musicPlaybackDescription),
                    detail: languageSettings.permissionSettingsText(.thirdPartyMusicAutomationHint),
                    actionTitle: languageSettings.permissionSettingsText(.openAutomationSettings),
                    action: openAutomationSettings
                )
            }

            HStack {
                Button(languageSettings.permissionSettingsText(.refreshStatus)) {
                    refreshInputMonitoringStatus()
                }

                Spacer()

                Button(languageSettings.text(.ok), action: onClose)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 540, height: 650)
        .onAppear(perform: refreshInputMonitoringStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            refreshInputMonitoringStatus()
        }
    }

    private func refreshInputMonitoringStatus() {
        inputMonitoringAllowed = isInputMonitoringAllowed()
    }
}

private struct MusicAppPermissionRow: View {
    let iconResourceName: String
    let title: String
    let description: String
    let detail: String
    let actionTitle: String
    let action: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            musicAppIcon
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(detail)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 12)

            Button(actionTitle, action: action)
                .controlSize(.small)
        }
    }

    @ViewBuilder
    private var musicAppIcon: some View {
        if let url = PetResourceURLCache.url(named: iconResourceName, withExtension: "png"),
           let icon = PetImportedImageCache.image(for: url)
        {
            Image(nsImage: icon)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
        }
    }
}

private struct PermissionSection: View {
    let icon: String
    let title: String
    let description: String
    var detail: String?
    var status: String?
    var isAllowed: Bool?
    let actionTitle: String
    let action: () -> Void
    var usesCardBackground = true

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 7) {
                    Text(title)
                        .font(.headline)
                    if let status, let isAllowed {
                        Label(status, systemImage: isAllowed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(isAllowed ? .green : .orange)
                    }
                }
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Button(actionTitle, action: action)
                .controlSize(.small)
        }
        .padding(usesCardBackground ? 14 : 0)
        .background {
            if usesCardBackground {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor))
            }
        }
    }
}

private struct PermissionGroup<Content: View>: View {
    let icon: String
    let title: String
    let description: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .frame(width: 24)
                    .foregroundStyle(Color.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            content()
                .padding(.leading, 36)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
    }
}
