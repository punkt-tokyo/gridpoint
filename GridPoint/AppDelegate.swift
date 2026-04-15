import AppKit
import SwiftUI
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var cancellables = Set<AnyCancellable>()

    private var toggleItem: NSMenuItem?
    private var cellSizeView: GridSizeView?
    private var opacityLabel: NSTextField?
    private var opacitySlider: NSSlider?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        buildMenu()
        GridWindowController.shared.setupWindows()
        HotKeyManager.shared.registerAll()

        GridSettings.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.updateMenuState()
            }
            .store(in: &cancellables)
    }

    // MARK: - Menu bar

    private func buildMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "square.grid.3x3", accessibilityDescription: "GridPoint")
        }

        let menu = NSMenu()
        menu.autoenablesItems = false

        let toggle = NSMenuItem(title: "", action: #selector(toggleGrid), keyEquivalent: "g")
        toggle.keyEquivalentModifierMask = [.command, .shift]
        toggle.target = self
        menu.addItem(toggle)
        self.toggleItem = toggle

        menu.addItem(.separator())

        menu.addItem(makeCellSizeItem())
        menu.addItem(makeOpacitySliderItem())

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: "")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit GridPoint", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        updateMenuState()
    }

    private func updateMenuState() {
        let settings = GridSettings.shared
        toggleItem?.title = settings.isVisible ? "Hide Grid" : "Show Grid"

        if let view = cellSizeView {
            view.cellWidth = settings.cellWidth
            view.cellHeight = settings.cellHeight
        }

        opacityLabel?.stringValue = String(format: "Opacity: %.2f", settings.opacity)
        if let slider = opacitySlider, slider.doubleValue != settings.opacity {
            slider.doubleValue = settings.opacity
        }
    }

    private func makeCellSizeItem() -> NSMenuItem {
        let view = GridSizeView(frame: NSRect(x: 0, y: 0, width: 240, height: 200))
        view.cellWidth = GridSettings.shared.cellWidth
        view.cellHeight = GridSettings.shared.cellHeight
        view.onChange = { w, h in
            GridSettings.shared.cellWidth = w
            GridSettings.shared.cellHeight = h
            GridWindowController.shared.forceRedraw()
        }
        self.cellSizeView = view

        let item = NSMenuItem()
        item.view = view
        return item
    }

    private func makeOpacitySliderItem() -> NSMenuItem {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 240, height: 44))

        let label = NSTextField(labelWithString: "")
        label.frame = NSRect(x: 14, y: 22, width: 220, height: 18)
        label.font = NSFont.menuFont(ofSize: 0)
        container.addSubview(label)

        let slider = NSSlider(
            value: GridSettings.shared.opacity,
            minValue: 0.05, maxValue: 0.5,
            target: self, action: #selector(opacityChanged(_:))
        )
        slider.frame = NSRect(x: 14, y: 4, width: 220, height: 18)
        container.addSubview(slider)

        self.opacityLabel = label
        self.opacitySlider = slider

        let item = NSMenuItem()
        item.view = container
        return item
    }

    // MARK: - Actions

    @objc private func toggleGrid() {
        GridSettings.shared.toggleVisible()
        GridWindowController.shared.apply()
    }

    @objc private func opacityChanged(_ sender: NSSlider) {
        GridSettings.shared.opacity = sender.doubleValue
        opacityLabel?.stringValue = String(format: "Opacity: %.2f", GridSettings.shared.opacity)
        GridWindowController.shared.forceRedraw()
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = "GridPoint Settings"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - GridSizeView

final class GridSizeView: NSView {
    var onChange: ((Double, Double) -> Void)?

    var cellWidth: Double = 200 {
        didSet { needsDisplay = true }
    }
    var cellHeight: Double = 200 {
        didSet { needsDisplay = true }
    }

    private let anchorPoint = NSPoint(x: 30, y: 28)
    private let previewScale: CGFloat = 0.5
    private let minCell: Double = 50
    private let maxCell: Double = 300

    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let maxPreview = CGFloat(maxCell) * previewScale
        let maxRect = NSRect(x: anchorPoint.x, y: anchorPoint.y, width: maxPreview, height: maxPreview)

        NSColor.gray.withAlphaComponent(0.12).setFill()
        NSBezierPath(rect: maxRect).fill()
        NSColor.gray.withAlphaComponent(0.4).setStroke()
        let maxPath = NSBezierPath(rect: maxRect)
        maxPath.lineWidth = 0.5
        maxPath.setLineDash([2, 2], count: 2, phase: 0)
        maxPath.stroke()

        let w = CGFloat(cellWidth) * previewScale
        let h = CGFloat(cellHeight) * previewScale
        let rect = NSRect(x: anchorPoint.x, y: anchorPoint.y, width: w, height: h)

        NSColor.controlAccentColor.withAlphaComponent(0.25).setFill()
        NSBezierPath(rect: rect).fill()
        NSColor.controlAccentColor.setStroke()
        let path = NSBezierPath(rect: rect)
        path.lineWidth = 1.5
        path.stroke()

        let handleSize: CGFloat = 8
        let handleRect = NSRect(
            x: rect.maxX - handleSize / 2,
            y: rect.maxY - handleSize / 2,
            width: handleSize, height: handleSize
        )
        NSColor.controlAccentColor.setFill()
        NSBezierPath(ovalIn: handleRect).fill()

        let label = String(format: "%.0f × %.0f px", cellWidth, cellHeight)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.menuFont(ofSize: 0),
            .foregroundColor: NSColor.labelColor
        ]
        let attrString = NSAttributedString(string: label, attributes: attrs)
        let labelSize = attrString.size()
        let labelPoint = NSPoint(
            x: (bounds.width - labelSize.width) / 2,
            y: 6
        )
        attrString.draw(at: labelPoint)
    }

    override func mouseDown(with event: NSEvent) { update(event) }
    override func mouseDragged(with event: NSEvent) { update(event) }

    private func update(_ event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let rawW = Double((p.x - anchorPoint.x) / previewScale)
        let rawH = Double((p.y - anchorPoint.y) / previewScale)
        let clampedW = min(max(rawW, minCell), maxCell)
        let clampedH = min(max(rawH, minCell), maxCell)
        cellWidth = clampedW
        cellHeight = clampedH
        onChange?(clampedW, clampedH)
    }
}
