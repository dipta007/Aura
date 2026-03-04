import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    let displayManager = DisplayManager()
    lazy var engine = AdaptiveEngine(displayManager: displayManager)
    lazy var keyboardHandler = KeyboardBrightnessHandler(displayManager: displayManager, brightnessController: engine.brightnessController)

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Disable automatic termination for menu-bar-only app
        NSApp.disableRelaunchOnLogin()
        ProcessInfo.processInfo.disableSuddenTermination()
        ProcessInfo.processInfo.disableAutomaticTermination("Menu bar app")

        // Request screen capture permission only once
        if !CGPreflightScreenCaptureAccess() {
            let hasRequested = UserDefaults.standard.bool(forKey: "hasRequestedScreenCapture")
            if !hasRequested {
                CGRequestScreenCaptureAccess()
                UserDefaults.standard.set(true, forKey: "hasRequestedScreenCapture")
            }
        }

        // Start the engine regardless — captures will return nil without permission
        // but the menu bar UI will still be visible
        displayManager.refresh()
        engine.start()
        keyboardHandler.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        keyboardHandler.stop()
        engine.stop()
        CGDisplayRestoreColorSyncSettings()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
