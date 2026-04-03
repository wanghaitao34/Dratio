import SwiftUI

struct MenuView: View {

    let windowManager: WindowManager
    let hotKeyManager: HotKeyManager
    let permissionHelper: PermissionHelper
    @Binding var selectedRatio: RatioPreset

    @Environment(\.openWindow) private var openWindow
    @State private var feedbackPreset: RatioPreset?
    @State private var hoveredItem: String?

    var body: some View {
        VStack(spacing: 0) {
            if !permissionHelper.isAccessibilityGranted {
                permissionBanner
            }

            ratioSection
            menuDivider
            scaleSection
            menuDivider
            bottomSection
        }
        .padding(.vertical, 8)
        .frame(width: 240)
    }

    private var menuDivider: some View {
        Divider().padding(.vertical, 4).padding(.horizontal, 12)
    }

    // MARK: - Permission banner

    private var permissionBanner: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("menu.permission.needed")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Button("menu.permission.go") {
                permissionHelper.requestAccessibility()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.yellow.opacity(0.1))
    }

    // MARK: - Ratio buttons

    private var ratioSection: some View {
        VStack(spacing: 1) {
            ForEach(RatioPreset.allCases) { preset in
                menuRow(
                    id: "ratio-\(preset.id)",
                    icon: { RatioIcon(preset: preset).frame(width: 18, height: 18) },
                    title: preset.label,
                    trailing: hotKeyManager.binding(for: actionForPreset(preset)).displayString,
                    isSelected: selectedRatio == preset,
                    showCheck: feedbackPreset == preset
                ) {
                    selectedRatio = preset
                    windowManager.applyRatio(preset)
                    showFeedback(preset)
                }
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Scale buttons

    private var scaleSection: some View {
        VStack(spacing: 1) {
            menuRow(
                id: "scale-up",
                systemIcon: "plus.magnifyingglass",
                title: String(localized: "menu.scale.up"),
                trailing: hotKeyManager.binding(for: .scaleUp).displayString
            ) {
                windowManager.scaleUp()
            }

            menuRow(
                id: "scale-down",
                systemIcon: "minus.magnifyingglass",
                title: String(localized: "menu.scale.down"),
                trailing: hotKeyManager.binding(for: .scaleDown).displayString
            ) {
                windowManager.scaleDown()
            }

            menuRow(
                id: "maximize",
                systemIcon: "arrow.up.left.and.arrow.down.right",
                title: "\(String(localized: "hotkey.maximize")) \(selectedRatio.label)",
                trailing: hotKeyManager.binding(for: .maximize).displayString
            ) {
                windowManager.maximize(ratio: selectedRatio)
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Bottom section

    private var bottomSection: some View {
        VStack(spacing: 1) {
            menuRow(
                id: "help",
                systemIcon: "questionmark.circle",
                title: String(localized: "menu.help")
            ) {
                openWindow(id: "help")
                NSApp.activate(ignoringOtherApps: true)
            }

            menuRow(
                id: "settings",
                systemIcon: "gearshape",
                title: String(localized: "menu.settings")
            ) {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }

            menuRow(
                id: "quit",
                systemIcon: "power",
                title: String(localized: "menu.quit")
            ) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 6)
    }

    // MARK: - Generic menu row with hover highlight

    private func menuRow<Icon: View>(
        id: String,
        @ViewBuilder icon: () -> Icon,
        title: String,
        trailing: String? = nil,
        isSelected: Bool = false,
        showCheck: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon()
                    .frame(width: 18)

                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if showCheck {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                }

                if let trailing {
                    Text(trailing)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.08))
                        )
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(backgroundColor(id: id, isSelected: isSelected))
        )
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredItem = isHovered ? id : (hoveredItem == id ? nil : hoveredItem)
            }
        }
    }

    private func menuRow(
        id: String,
        systemIcon: String,
        title: String,
        trailing: String? = nil,
        isSelected: Bool = false,
        showCheck: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        menuRow(
            id: id,
            icon: { Image(systemName: systemIcon).frame(width: 18) },
            title: title,
            trailing: trailing,
            isSelected: isSelected,
            showCheck: showCheck,
            action: action
        )
    }

    private func backgroundColor(id: String, isSelected: Bool) -> Color {
        if hoveredItem == id {
            return Color.accentColor.opacity(0.18)
        }
        return .clear
    }

    // MARK: - Helpers

    private func actionForPreset(_ preset: RatioPreset) -> HotKeyAction {
        switch preset {
        case .r16x9:  return .ratio16x9
        case .r16x10: return .ratio16x10
        case .r4x3:   return .ratio4x3
        case .r1x1:   return .ratio1x1
        case .r3x4:   return .ratio3x4
        case .r9x16:  return .ratio9x16
        }
    }

    private func showFeedback(_ preset: RatioPreset) {
        withAnimation(.easeInOut(duration: 0.2)) {
            feedbackPreset = preset
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                if feedbackPreset == preset { feedbackPreset = nil }
            }
        }
    }
}

// MARK: - Ratio Icon

struct RatioIcon: View {
    let preset: RatioPreset

    var body: some View {
        GeometryReader { geo in
            let maxDim = min(geo.size.width, geo.size.height) * 0.85
            let iconWidth = preset.ratio >= 1 ? maxDim : maxDim * preset.ratio
            let iconHeight = preset.ratio >= 1 ? maxDim / preset.ratio : maxDim

            RoundedRectangle(cornerRadius: 1.5)
                .stroke(Color.secondary, lineWidth: 1.2)
                .frame(width: iconWidth, height: iconHeight)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
