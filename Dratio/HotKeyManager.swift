import Carbon
import AppKit

struct HotKeyBinding: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    var carbonModifiers: UInt32 {
        var m: UInt32 = 0
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 { m |= UInt32(cmdKey) }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0  { m |= UInt32(optionKey) }
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 { m |= UInt32(controlKey) }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0   { m |= UInt32(shiftKey) }
        return m
    }

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(NSEvent.ModifierFlags.control.rawValue) != 0 { parts.append("⌃") }
        if modifiers & UInt32(NSEvent.ModifierFlags.option.rawValue) != 0  { parts.append("⌥") }
        if modifiers & UInt32(NSEvent.ModifierFlags.shift.rawValue) != 0   { parts.append("⇧") }
        if modifiers & UInt32(NSEvent.ModifierFlags.command.rawValue) != 0 { parts.append("⌘") }
        parts.append(keyCodeToString(keyCode))
        return parts.joined()
    }
}

private func keyCodeToString(_ keyCode: UInt32) -> String {
    let map: [UInt32: String] = [
        18: "1", 19: "2", 20: "3", 21: "4", 23: "5",
        22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
        24: "=", 27: "-",
        0: "A", 11: "B", 8: "C", 2: "D", 14: "E",
        3: "F", 5: "G", 4: "H", 34: "I", 38: "J",
        40: "K", 37: "L", 46: "M", 45: "N", 31: "O",
        35: "P", 12: "Q", 15: "R", 1: "S", 17: "T",
        32: "U", 9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
    ]
    return map[keyCode] ?? "?"
}

enum HotKeyAction: String, CaseIterable, Codable {
    case ratio16x9
    case ratio16x10
    case ratio4x3
    case ratio1x1
    case ratio3x4
    case ratio9x16
    case scaleUp
    case scaleDown
    case maximize

    var label: String {
        switch self {
        case .ratio16x9:  return "16:9"
        case .ratio16x10: return "16:10"
        case .ratio4x3:   return "4:3"
        case .ratio1x1:   return "1:1"
        case .ratio3x4:   return "3:4"
        case .ratio9x16:  return "9:16"
        case .scaleUp:    return String(localized: "hotkey.scaleUp")
        case .scaleDown:  return String(localized: "hotkey.scaleDown")
        case .maximize:   return String(localized: "hotkey.maximize")
        }
    }

    var ratioPreset: RatioPreset? {
        switch self {
        case .ratio16x9:  return .r16x9
        case .ratio16x10: return .r16x10
        case .ratio4x3:   return .r4x3
        case .ratio1x1:   return .r1x1
        case .ratio3x4:   return .r3x4
        case .ratio9x16:  return .r9x16
        default: return nil
        }
    }

    var defaultBinding: HotKeyBinding {
        let optCmd = UInt32(NSEvent.ModifierFlags.option.rawValue | NSEvent.ModifierFlags.command.rawValue)
        switch self {
        case .ratio16x9:  return HotKeyBinding(keyCode: 18, modifiers: optCmd) // ⌥⌘1
        case .ratio16x10: return HotKeyBinding(keyCode: 19, modifiers: optCmd) // ⌥⌘2
        case .ratio4x3:   return HotKeyBinding(keyCode: 20, modifiers: optCmd) // ⌥⌘3
        case .ratio1x1:   return HotKeyBinding(keyCode: 21, modifiers: optCmd) // ⌥⌘4
        case .ratio3x4:   return HotKeyBinding(keyCode: 23, modifiers: optCmd) // ⌥⌘5
        case .ratio9x16:  return HotKeyBinding(keyCode: 22, modifiers: optCmd) // ⌥⌘6
        case .scaleUp:    return HotKeyBinding(keyCode: 24, modifiers: optCmd) // ⌥⌘=
        case .scaleDown:  return HotKeyBinding(keyCode: 27, modifiers: optCmd) // ⌥⌘-
        case .maximize:   return HotKeyBinding(keyCode: 46, modifiers: optCmd) // ⌥⌘M
        }
    }
}

@Observable
final class HotKeyManager {

    var bindings: [HotKeyAction: HotKeyBinding] = [:]

    private var hotKeyRefs: [HotKeyAction: EventHotKeyRef] = [:]
    private var handler: ((HotKeyAction) -> Void)?

    private static let hotKeySignature: UInt32 = {
        let chars: [UInt8] = [0x44, 0x52, 0x54, 0x4F] // "DRTO"
        return chars.withUnsafeBufferPointer { buf in
            buf.baseAddress!.withMemoryRebound(to: UInt32.self, capacity: 1) { $0.pointee }
        }
    }()

    init() {
        loadBindings()
    }

    func start(handler: @escaping (HotKeyAction) -> Void) {
        self.handler = handler
        installCarbonHandler()
        registerAll()
    }

    func stop() {
        unregisterAll()
    }

    func updateBinding(for action: HotKeyAction, binding: HotKeyBinding) {
        unregister(action: action)
        bindings[action] = binding
        register(action: action)
        saveBindings()
    }

    func resetToDefaults() {
        unregisterAll()
        for action in HotKeyAction.allCases {
            bindings[action] = action.defaultBinding
        }
        registerAll()
        saveBindings()
    }

    func binding(for action: HotKeyAction) -> HotKeyBinding {
        bindings[action] ?? action.defaultBinding
    }

    // MARK: - Persistence

    private func loadBindings() {
        if let data = UserDefaults.standard.data(forKey: "hotKeyBindings"),
           let decoded = try? JSONDecoder().decode([String: HotKeyBinding].self, from: data) {
            for action in HotKeyAction.allCases {
                bindings[action] = decoded[action.rawValue] ?? action.defaultBinding
            }
        } else {
            for action in HotKeyAction.allCases {
                bindings[action] = action.defaultBinding
            }
        }
    }

    private func saveBindings() {
        let dict = Dictionary(uniqueKeysWithValues: bindings.map { ($0.key.rawValue, $0.value) })
        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: "hotKeyBindings")
        }
    }

    // MARK: - Carbon registration

    private func installCarbonHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData -> OSStatus in
                guard let userData else { return OSStatus(eventNotHandledErr) }
                let mgr = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    UInt32(kEventParamDirectObject),
                    UInt32(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                let idx = Int(hotKeyID.id)
                let allActions = HotKeyAction.allCases
                guard idx >= 0 && idx < allActions.count else { return OSStatus(eventNotHandledErr) }

                mgr.handler?(allActions[idx])
                return noErr
            },
            1,
            &eventType,
            selfPtr,
            nil
        )
    }

    private func registerAll() {
        for action in HotKeyAction.allCases {
            register(action: action)
        }
    }

    private func unregisterAll() {
        for action in HotKeyAction.allCases {
            unregister(action: action)
        }
    }

    private func register(action: HotKeyAction) {
        let b = binding(for: action)
        let idx = HotKeyAction.allCases.firstIndex(of: action)!

        let hotKeyID = EventHotKeyID(
            signature: Self.hotKeySignature,
            id: UInt32(idx)
        )

        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            b.keyCode,
            b.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr, let ref {
            hotKeyRefs[action] = ref
        }
    }

    private func unregister(action: HotKeyAction) {
        if let ref = hotKeyRefs.removeValue(forKey: action) {
            UnregisterEventHotKey(ref)
        }
    }
}
