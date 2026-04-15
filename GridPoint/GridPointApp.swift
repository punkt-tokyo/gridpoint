import SwiftUI

@main
struct GridPointApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // AppDelegate manages its own settings NSWindow (required for .accessory apps).
        // This scene exists only because SwiftUI.App requires a Scene body.
        Settings {
            EmptyView()
        }
    }
}
