import SwiftUI
import ServiceManagement

enum AppLanguage: String, CaseIterable {
    case system = "system"
    case zhHans = "zh-Hans"
    case en = "en"

    var displayName: String {
        switch self {
        case .system: return String(localized: "settings.appearance.auto")
        case .zhHans: return "中文"
        case .en:     return "English"
        }
    }
}

enum AppAppearance: String, CaseIterable {
    case auto  = "auto"
    case light = "light"
    case dark  = "dark"

    var displayName: String {
        switch self {
        case .auto:  return String(localized: "settings.appearance.auto")
        case .light: return String(localized: "settings.appearance.light")
        case .dark:  return String(localized: "settings.appearance.dark")
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct SettingsView: View {

    let hotKeyManager: HotKeyManager
    let permissionHelper: PermissionHelper

    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var recordingAction: HotKeyAction?
    @AppStorage("appLanguage") private var language: String = "system"
    @AppStorage("appAppearance") private var appearance: String = "auto"

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    shortcutSection
                    Divider()
                    generalSection
                    Divider()
                    permissionSection
                }
                .padding(20)
            }
        }
        .frame(width: 440, height: 520)
        .preferredColorScheme(AppAppearance(rawValue: appearance)?.colorScheme)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Image(systemName: "aspectratio")
                .font(.title2)
            Text("settings.title")
                .font(.headline)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    // MARK: - Section header

    private func sectionHeader(_ titleKey: LocalizedStringKey, icon: String) -> some View {
        Label(titleKey, systemImage: icon)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.bottom, 2)
    }

    // MARK: - Shortcut section

    private var shortcutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("settings.shortcuts", icon: "keyboard")

            VStack(spacing: 4) {
                ForEach(HotKeyAction.allCases, id: \.rawValue) { action in
                    shortcutRow(action)
                }
            }

            HStack {
                Spacer()
                Button("settings.shortcuts.reset") {
                    hotKeyManager.resetToDefaults()
                }
                .controlSize(.small)
            }
        }
    }

    private func shortcutRow(_ action: HotKeyAction) -> some View {
        HStack {
            Text(action.label)
                .frame(maxWidth: .infinity, alignment: .leading)

            if recordingAction == action {
                ShortcutRecorderView { event in
                    if let event {
                        let binding = HotKeyBinding(
                            keyCode: UInt32(event.keyCode),
                            modifiers: UInt32(event.modifierFlags.intersection(.deviceIndependentFlagsMask).rawValue)
                        )
                        hotKeyManager.updateBinding(for: action, binding: binding)
                    }
                    recordingAction = nil
                }
                .frame(width: 140, height: 24)
            } else {
                Button {
                    recordingAction = action
                } label: {
                    Text(hotKeyManager.binding(for: action).displayString)
                        .font(.system(.body, design: .monospaced))
                        .frame(width: 140, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - General section

    private var generalSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("settings.general", icon: "gearshape")

            Toggle("settings.launch.login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                    }
                }

            HStack {
                Text("settings.language")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: $language) {
                    ForEach(AppLanguage.allCases, id: \.rawValue) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
                .onChange(of: language) { _, newValue in
                    applyLanguage(newValue)
                }
            }

            HStack {
                Text("settings.appearance")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Picker("", selection: $appearance) {
                    ForEach(AppAppearance.allCases, id: \.rawValue) { mode in
                        Text(mode.displayName).tag(mode.rawValue)
                    }
                }
                .labelsHidden()
                .frame(width: 140)
                .onChange(of: appearance) { _, newValue in
                    applyAppearance(newValue)
                }
            }
        }
    }

    // MARK: - Permission section

    private var permissionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader("settings.permission", icon: "lock.shield")

            HStack {
                Image(systemName: permissionHelper.isAccessibilityGranted
                      ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(permissionHelper.isAccessibilityGranted ? .green : .red)
                Text("settings.permission.accessibility")
                Spacer()
                if !permissionHelper.isAccessibilityGranted {
                    Button("settings.permission.grant") {
                        permissionHelper.requestAccessibility()
                    }
                    .controlSize(.small)
                } else {
                    Text("settings.permission.granted")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Button("settings.permission.refresh") {
                permissionHelper.checkAccessibility()
            }
            .controlSize(.small)
        }
    }

    // MARK: - Language / Appearance logic

    private func applyLanguage(_ lang: String) {
        if lang == "system" {
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.set([lang], forKey: "AppleLanguages")
        }
    }

    private func applyAppearance(_ mode: String) {
        switch mode {
        case "light":
            NSApp.appearance = NSAppearance(named: .aqua)
        case "dark":
            NSApp.appearance = NSAppearance(named: .darkAqua)
        default:
            NSApp.appearance = nil
        }
    }
}

// MARK: - Shortcut Recorder

struct ShortcutRecorderView: NSViewRepresentable {

    var onRecord: (NSEvent?) -> Void

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let view = ShortcutRecorderNSView()
        view.onRecord = onRecord
        return view
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.onRecord = onRecord
    }
}

final class ShortcutRecorderNSView: NSView {

    var onRecord: ((NSEvent?) -> Void)?
    private var monitor: Any?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
        startMonitoring()
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let path = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        NSColor.controlAccentColor.withAlphaComponent(0.3).setFill()
        path.fill()
        NSColor.controlAccentColor.setStroke()
        path.lineWidth = 1.5
        path.stroke()

        let str = String(localized: "shortcut.record") as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor,
        ]
        let size = str.size(withAttributes: attrs)
        let point = NSPoint(
            x: (bounds.width - size.width) / 2,
            y: (bounds.height - size.height) / 2
        )
        str.draw(at: point, withAttributes: attrs)
    }

    private func startMonitoring() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let hasModifier = !flags.isSubset(of: [.capsLock, .numericPad, .function])

            if event.keyCode == 53 {
                self?.stopMonitoring()
                self?.onRecord?(nil)
                return nil
            }

            if hasModifier {
                self?.stopMonitoring()
                self?.onRecord?(event)
                return nil
            }

            return event
        }
    }

    private func stopMonitoring() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }

    deinit {
        stopMonitoring()
    }
}
