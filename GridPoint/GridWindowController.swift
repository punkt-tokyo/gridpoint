import AppKit
import SwiftUI

final class GridWindowController {
    static let shared = GridWindowController()

    private var windows: [NSWindow] = []

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func setupWindows() {
        rebuild()
        if GridSettings.shared.isVisible {
            show()
        }
    }

    @objc private func screensChanged() {
        let wasVisible = GridSettings.shared.isVisible
        rebuild()
        if wasVisible { show() }
    }

    private func rebuild() {
        for w in windows { w.orderOut(nil) }
        windows.removeAll()

        for screen in NSScreen.screens {
            let w = NSWindow(
                contentRect: NSRect(origin: .zero, size: screen.frame.size),
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            w.setFrame(screen.frame, display: false)
            w.backgroundColor = .clear
            w.isOpaque = false
            w.hasShadow = false
            w.level = .screenSaver
            w.ignoresMouseEvents = true
            w.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            w.isReleasedWhenClosed = false

            let host = NSHostingView(rootView: GridView())
            host.frame = NSRect(origin: .zero, size: screen.frame.size)
            host.autoresizingMask = [.width, .height]
            w.contentView = host

            windows.append(w)
        }
    }

    func show() {
        for w in windows { w.orderFrontRegardless() }
    }

    func hide() {
        for w in windows { w.orderOut(nil) }
    }

    func toggle() {
        if GridSettings.shared.isVisible {
            show()
        } else {
            hide()
        }
    }

    func apply() {
        if GridSettings.shared.isVisible {
            show()
        } else {
            hide()
        }
    }

    func forceRedraw() {
        for w in windows {
            if let host = w.contentView as? NSHostingView<GridView> {
                host.rootView = GridView()
            }
        }
    }
}
