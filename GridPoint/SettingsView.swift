import SwiftUI
import AppKit
import Carbon.HIToolbox

struct SettingsView: View {
    @ObservedObject var settings: GridSettings = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            ColorPicker("Grid Line Color", selection: $settings.gridColor, supportsOpacity: false)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                ForEach(HotKeyAction.allCases) { action in
                    HStack {
                        Text(action.title)
                        Spacer()
                        HotKeyField(action: action, settings: settings)
                            .frame(width: 200)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

private struct HotKeyField: View {
    let action: HotKeyAction
    @ObservedObject var settings: GridSettings
    @State private var recording = false
    @State private var monitor: Any?

    var body: some View {
        Button(action: toggleRecording) {
            Text(recording ? "Press a key…" : label)
                .frame(maxWidth: .infinity)
        }
    }

    private var label: String {
        guard let b = settings.hotKeys[action] else { return "Not set" }
        return HotKeyField.describe(keyCode: b.keyCode, modifiers: b.modifiers)
    }

    private func toggleRecording() {
        if recording { stop() } else { start() }
    }

    private func start() {
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let mods = Self.carbonFlags(from: event.modifierFlags)
            let code = UInt32(event.keyCode)
            settings.hotKeys[action] = HotKeyBinding(keyCode: code, modifiers: mods)
            HotKeyManager.shared.reregister()
            stop()
            return nil
        }
    }

    private func stop() {
        recording = false
        if let m = monitor {
            NSEvent.removeMonitor(m)
            monitor = nil
        }
    }

    static func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var r: UInt32 = 0
        if flags.contains(.command) { r |= UInt32(cmdKey) }
        if flags.contains(.shift)   { r |= UInt32(shiftKey) }
        if flags.contains(.option)  { r |= UInt32(optionKey) }
        if flags.contains(.control) { r |= UInt32(controlKey) }
        return r
    }

    static func describe(keyCode: UInt32, modifiers: UInt32) -> String {
        var s = ""
        if modifiers & UInt32(controlKey) != 0 { s += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { s += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { s += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { s += "⌘" }
        s += keyName(for: keyCode)
        return s
    }

    static func keyName(for code: UInt32) -> String {
        let map: [UInt32: String] = [
            0x00: "A", 0x0B: "B", 0x08: "C", 0x02: "D", 0x0E: "E",
            0x03: "F", 0x05: "G", 0x04: "H", 0x22: "I", 0x26: "J",
            0x28: "K", 0x25: "L", 0x2E: "M", 0x2D: "N", 0x1F: "O",
            0x23: "P", 0x0C: "Q", 0x0F: "R", 0x01: "S", 0x11: "T",
            0x20: "U", 0x09: "V", 0x0D: "W", 0x07: "X", 0x10: "Y",
            0x06: "Z",
            0x12: "1", 0x13: "2", 0x14: "3", 0x15: "4", 0x17: "5",
            0x16: "6", 0x1A: "7", 0x1C: "8", 0x19: "9", 0x1D: "0",
            0x1B: "-", 0x18: "=", 0x21: "[", 0x1E: "]", 0x2A: "\\",
            0x29: ";", 0x27: "'", 0x2B: ",", 0x2F: ".", 0x2C: "/",
            0x31: "Space", 0x24: "Return", 0x35: "Esc", 0x30: "Tab",
        ]
        return map[code] ?? "Key(\(code))"
    }
}
