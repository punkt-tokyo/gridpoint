import SwiftUI
import AppKit
import Combine

extension Notification.Name {
    static let gridSettingsChanged = Notification.Name("tokyo.punkt.GridPoint.settingsChanged")
}

enum HotKeyAction: String, CaseIterable, Identifiable {
    case toggle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .toggle: return "Show/Hide Grid"
        }
    }
}

struct HotKeyBinding: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32
}

final class GridSettings: ObservableObject {
    static let shared = GridSettings()

    private let defaults = UserDefaults.standard

    @Published var cellWidth: Double {
        didSet {
            let clamped = min(max(cellWidth, 50), 300)
            if cellWidth != clamped {
                cellWidth = clamped
                return
            }
            defaults.set(cellWidth, forKey: Keys.cellWidth)
            notifyChange()
        }
    }

    @Published var cellHeight: Double {
        didSet {
            let clamped = min(max(cellHeight, 50), 300)
            if cellHeight != clamped {
                cellHeight = clamped
                return
            }
            defaults.set(cellHeight, forKey: Keys.cellHeight)
            notifyChange()
        }
    }

    @Published var opacity: Double {
        didSet {
            let clamped = min(max(opacity, 0.05), 0.5)
            if opacity != clamped {
                opacity = clamped
                return
            }
            defaults.set(opacity, forKey: Keys.opacity)
            notifyChange()
        }
    }

    @Published var gridColor: Color {
        didSet {
            if let data = encodeColor(gridColor) {
                defaults.set(data, forKey: Keys.gridColor)
            }
            notifyChange()
        }
    }

    @Published var isVisible: Bool {
        didSet {
            defaults.set(isVisible, forKey: Keys.isVisible)
            notifyChange()
        }
    }

    @Published var hotKeys: [HotKeyAction: HotKeyBinding] {
        didSet {
            if let data = try? JSONEncoder().encode(hotKeys.reduce(into: [String: HotKeyBinding]()) { $0[$1.key.rawValue] = $1.value }) {
                defaults.set(data, forKey: Keys.hotKeys)
            }
        }
    }

    private enum Keys {
        static let cellWidth  = "cellWidth"
        static let cellHeight = "cellHeight"
        static let opacity    = "opacity"
        static let gridColor  = "gridColor"
        static let isVisible  = "isVisible"
        static let hotKeys    = "hotKeys"
    }

    private init() {
        if defaults.object(forKey: Keys.cellWidth) == nil {
            self.cellWidth = 200
        } else {
            self.cellWidth = defaults.double(forKey: Keys.cellWidth)
        }

        if defaults.object(forKey: Keys.cellHeight) == nil {
            self.cellHeight = 200
        } else {
            self.cellHeight = defaults.double(forKey: Keys.cellHeight)
        }

        if defaults.object(forKey: Keys.opacity) == nil {
            self.opacity = 0.3
        } else {
            self.opacity = defaults.double(forKey: Keys.opacity)
        }

        if let data = defaults.data(forKey: Keys.gridColor),
           let color = GridSettings.decodeColor(data) {
            self.gridColor = color
        } else {
            self.gridColor = .white
        }

        self.isVisible = defaults.bool(forKey: Keys.isVisible)

        var loaded: [HotKeyAction: HotKeyBinding] = GridSettings.defaultHotKeys
        if let data = defaults.data(forKey: Keys.hotKeys),
           let decoded = try? JSONDecoder().decode([String: HotKeyBinding].self, from: data) {
            for (k, v) in decoded {
                if let action = HotKeyAction(rawValue: k) {
                    loaded[action] = v
                }
            }
        }
        self.hotKeys = loaded
    }

    private func notifyChange() {
        NotificationCenter.default.post(name: .gridSettingsChanged, object: nil)
    }

    static let defaultHotKeys: [HotKeyAction: HotKeyBinding] = [
        // cmdKey = 256, shiftKey = 512, cmd+shift = 768
        .toggle: HotKeyBinding(keyCode: 0x05, modifiers: 768),   // G
    ]

    // MARK: - Color encode/decode

    private func encodeColor(_ color: Color) -> Data? {
        let ns = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.white
        let rgba: [CGFloat] = [ns.redComponent, ns.greenComponent, ns.blueComponent, ns.alphaComponent]
        return try? JSONEncoder().encode(rgba.map { Double($0) })
    }

    private static func decodeColor(_ data: Data) -> Color? {
        guard let arr = try? JSONDecoder().decode([Double].self, from: data), arr.count == 4 else { return nil }
        return Color(.sRGB, red: arr[0], green: arr[1], blue: arr[2], opacity: arr[3])
    }

    // MARK: - Mutators

    func toggleVisible() {
        isVisible.toggle()
    }

}
