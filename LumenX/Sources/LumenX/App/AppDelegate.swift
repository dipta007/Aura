import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let displayManager = DisplayManager()
    lazy var engine = AdaptiveEngine(displayManager: displayManager)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Request screen capture permission
        let hasPermission = CGPreflightScreenCaptureAccess()
        if !hasPermission {
            CGRequestScreenCaptureAccess()
            let alert = NSAlert()
            alert.messageText = "Screen Recording Permission Required"
            alert.informativeText = "LumenX needs screen recording access to analyze what's on each display and adjust brightness accordingly. Please grant access in System Settings → Privacy & Security → Screen Recording, then relaunch the app."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Quit")

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            }
            NSApplication.shared.terminate(nil)
            return
        }

        // Start the engine
        displayManager.refresh()
        engine.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stop()
        // Restore all displays to their gamma tables
        CGDisplayRestoreColorSyncSettings()
    }
}
