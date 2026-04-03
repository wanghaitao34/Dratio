import AppKit
import ApplicationServices

@Observable
final class WindowManager {

    private(set) var lastError: String?
    private var previousApp: NSRunningApplication?
    private var observer: NSObjectProtocol?

    init() {
        let ownBundleID = Bundle.main.bundleIdentifier
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.bundleIdentifier != ownBundleID {
                self?.previousApp = app
            }
        }
    }

    deinit {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
    }

    // MARK: - Apply ratio to frontmost window

    func applyRatio(_ preset: RatioPreset) {
        guard let window = targetWindow() else { return }
        guard let frame = getFrame(window) else { return }
        let screen = screenFrame(for: frame)

        let newSize = preset.targetSize(
            currentWidth: frame.width,
            currentHeight: frame.height,
            screenFrame: screen
        )

        let center = CGPoint(x: frame.midX, y: frame.midY)
        let newOrigin = clampedOrigin(center: center, size: newSize, screen: screen)

        setFrame(window, origin: newOrigin, size: newSize)
    }

    // MARK: - Scale keeping current ratio

    func scaleUp() {
        scale(factor: 1.1)
    }

    func scaleDown() {
        scale(factor: 0.9)
    }

    private func scale(factor: CGFloat) {
        guard let window = targetWindow() else { return }
        guard let frame = getFrame(window) else { return }
        let screen = screenFrame(for: frame)

        let newSize = RatioPreset.scaledSize(
            currentWidth: frame.width,
            currentHeight: frame.height,
            factor: factor,
            screenFrame: screen
        )

        let center = CGPoint(x: frame.midX, y: frame.midY)
        let newOrigin = clampedOrigin(center: center, size: newSize, screen: screen)

        setFrame(window, origin: newOrigin, size: newSize)
    }

    // MARK: - Maximize with ratio

    func maximize(ratio preset: RatioPreset) {
        guard let window = targetWindow() else { return }
        guard let frame = getFrame(window) else { return }
        let screen = screenFrame(for: frame)

        let maxSize = preset.maximizedSize(in: screen)
        let centerOfScreen = CGPoint(
            x: screen.midX,
            y: screen.midY
        )
        let newOrigin = clampedOrigin(center: centerOfScreen, size: maxSize, screen: screen)

        setFrame(window, origin: newOrigin, size: maxSize)
    }

    // MARK: - AXUIElement helpers

    private func targetWindow() -> AXUIElement? {
        lastError = nil

        let frontApp = NSWorkspace.shared.frontmostApplication
        let isSelf = frontApp?.bundleIdentifier == Bundle.main.bundleIdentifier
        guard let app = (isSelf ? previousApp : frontApp) ?? frontApp else {
            lastError = "无法获取前台应用"
            return nil
        }

        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)

        var windowRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &windowRef)

        if result != .success {
            var windowsRef: CFTypeRef?
            let listResult = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef)
            if listResult == .success, let windows = windowsRef as? [AXUIElement], let first = windows.first {
                return first
            }
            lastError = "无法获取窗口（错误码: \(result.rawValue)）。请确认已授予辅助功能权限。"
            return nil
        }

        // swiftlint:disable:next force_cast
        return (windowRef as! AXUIElement)
    }

    private func getFrame(_ window: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?

        guard AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef) == .success
        else {
            lastError = "无法读取窗口位置/大小"
            return nil
        }

        var point = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &point)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)

        return CGRect(origin: point, size: size)
    }

    @discardableResult
    private func setFrame(_ window: AXUIElement, origin: CGPoint, size: CGSize) -> Bool {
        var newOrigin = origin
        var newSize = size

        guard let posVal = AXValueCreate(.cgPoint, &newOrigin),
              let sizeVal = AXValueCreate(.cgSize, &newSize)
        else { return false }

        let posOK = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, posVal) == .success
        let sizeOK = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeVal) == .success

        if !posOK || !sizeOK {
            lastError = "设置窗口尺寸失败，目标应用可能限制了窗口调整"
        }

        return posOK && sizeOK
    }

    // MARK: - Screen & geometry helpers

    private func screenFrame(for windowFrame: CGRect) -> CGRect {
        let windowCenter = CGPoint(x: windowFrame.midX, y: windowFrame.midY)
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(windowCenter)
        } ?? NSScreen.main ?? NSScreen.screens.first

        guard let visibleFrame = screen?.visibleFrame else {
            return CGRect(x: 0, y: 0, width: 1920, height: 1080)
        }

        // AX uses top-left origin; NSScreen uses bottom-left.
        // Convert visibleFrame to AX coordinate space.
        guard let mainScreen = NSScreen.screens.first else { return visibleFrame }
        let mainHeight = mainScreen.frame.height
        let axY = mainHeight - visibleFrame.maxY
        return CGRect(x: visibleFrame.origin.x, y: axY, width: visibleFrame.width, height: visibleFrame.height)
    }

    private func clampedOrigin(center: CGPoint, size: CGSize, screen: CGRect) -> CGPoint {
        var x = center.x - size.width / 2
        var y = center.y - size.height / 2

        x = max(screen.minX, min(x, screen.maxX - size.width))
        y = max(screen.minY, min(y, screen.maxY - size.height))

        return CGPoint(x: round(x), y: round(y))
    }
}
