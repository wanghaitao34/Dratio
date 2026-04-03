import SwiftUI

@main
struct DratioApp: App {

    @State private var appState = AppState()
    @AppStorage("appAppearance") private var appearance: String = "auto"
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra("Dratio", systemImage: "aspectratio") {
            MenuView(
                windowManager: appState.windowManager,
                hotKeyManager: appState.hotKeyManager,
                permissionHelper: appState.permissionHelper,
                selectedRatio: $appState.selectedRatio
            )
            .onAppear {
                appState.startHotKeys()
                applyAppearance(appearance)
            }
        }
        .menuBarExtraStyle(.window)

        Window("settings.title", id: "settings") {
            SettingsView(
                hotKeyManager: appState.hotKeyManager,
                permissionHelper: appState.permissionHelper
            )
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("help.title", id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Window("onboarding.title", id: "onboarding") {
            OnboardingView(permissionHelper: appState.permissionHelper)
                .onDisappear {
                    hasCompletedOnboarding = true
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
        .windowStyle(.hiddenTitleBar)
    }

    init() {
        if !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            NotificationCenter.default.addObserver(
                forName: NSApplication.didFinishLaunchingNotification,
                object: nil,
                queue: .main
            ) { [self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    openWindow(id: "onboarding")
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
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

@Observable
final class AppState {

    let windowManager = WindowManager()
    let hotKeyManager = HotKeyManager()
    let permissionHelper = PermissionHelper()

    var selectedRatio: RatioPreset = .r16x9

    private var hotKeysStarted = false

    func startHotKeys() {
        guard !hotKeysStarted else { return }
        hotKeysStarted = true

        hotKeyManager.start { [weak self] action in
            guard let self else { return }
            switch action {
            case .scaleUp:
                windowManager.scaleUp()
            case .scaleDown:
                windowManager.scaleDown()
            case .maximize:
                windowManager.maximize(ratio: selectedRatio)
            default:
                if let preset = action.ratioPreset {
                    selectedRatio = preset
                    windowManager.applyRatio(preset)
                }
            }
        }
    }
}
