import SwiftUI

@main
struct LumenXApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("LumenX", systemImage: "sun.max.fill") {
            MenuBarView(
                engine: appDelegate.engine,
                displayManager: appDelegate.displayManager
            )
        }
        .menuBarExtraStyle(.window)
    }
}
