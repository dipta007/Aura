import Cocoa
import CoreGraphics

private func debugLog(_ msg: String) {
    let line = "\(Date()): \(msg)\n"
    if let data = line.data(using: .utf8) {
        if let handle = FileHandle(forWritingAtPath: "/tmp/lumenx.log") {
            handle.seekToEndOfFile()
            handle.write(data)
            handle.closeFile()
        } else {
            FileManager.default.createFile(atPath: "/tmp/lumenx.log", contents: data)
        }
    }
}

class KeyboardBrightnessHandler {
    private let displayManager: DisplayManager
    private let brightnessController: BrightnessController
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private let step: Float = 0.0625 // 6.25% per press (16 steps 0→100)

    private static weak var instance: KeyboardBrightnessHandler?

    init(displayManager: DisplayManager, brightnessController: BrightnessController) {
        self.displayManager = displayManager
        self.brightnessController = brightnessController
        KeyboardBrightnessHandler.instance = self
    }

    func start() {
        let trusted = AXIsProcessTrustedWithOptions(
            [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        )
        debugLog("[Keyboard] Accessibility trusted: \(trusted)")

        if !trusted {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.start()
            }
            return
        }

        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << 14) // NX_SYSDEFINED

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, type, event, _ -> Unmanaged<CGEvent>? in
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    debugLog("[Keyboard] Event tap disabled, re-enabling")
                    if let instance = KeyboardBrightnessHandler.instance,
                       let tap = instance.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }
                KeyboardBrightnessHandler.instance?.handleCGEvent(event)
                return Unmanaged.passUnretained(event)
            },
            userInfo: nil
        ) else {
            debugLog("[Keyboard] Failed to create event tap")
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        debugLog("[Keyboard] Event tap created and enabled")
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            }
        }
        eventTap = nil
        runLoopSource = nil
    }

    private func handleCGEvent(_ event: CGEvent) {
        guard let nsEvent = NSEvent(cgEvent: event) else { return }
        guard nsEvent.subtype.rawValue == 8 else { return }

        let data1 = nsEvent.data1
        let keyCode = Int((data1 & 0xFFFF0000) >> 16)
        let keyState = (data1 & 0x0000FF00) >> 8

        guard keyState == 0x0A else { return } // key down only

        switch keyCode {
        case 2: // NX_KEYTYPE_BRIGHTNESS_UP
            adjustActiveDisplayBrightness(by: step)
        case 3: // NX_KEYTYPE_BRIGHTNESS_DOWN
            adjustActiveDisplayBrightness(by: -step)
        default:
            break
        }
    }

    /// Find the display under the mouse cursor
    private func activeDisplayID() -> CGDirectDisplayID? {
        let mouseLocation = NSEvent.mouseLocation
        // NSEvent.mouseLocation is in bottom-left origin; convert for CGDisplayBounds (top-left origin)
        guard let mainScreen = NSScreen.screens.first else { return nil }
        let screenHeight = mainScreen.frame.height
        let cgPoint = CGPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)

        var displayID: CGDirectDisplayID = 0
        var count: UInt32 = 0
        CGGetDisplaysWithPoint(cgPoint, 1, &displayID, &count)
        return count > 0 ? displayID : nil
    }

    private func adjustActiveDisplayBrightness(by delta: Float) {
        guard let activeID = activeDisplayID() else {
            debugLog("[Keyboard] No active display found")
            return
        }

        guard let index = displayManager.displays.firstIndex(where: { $0.id == activeID }) else {
            debugLog("[Keyboard] Active display \(activeID) not in display list")
            return
        }

        let display = displayManager.displays[index]
        guard !display.isBuiltIn, display.isEnabled else {
            debugLog("[Keyboard] Display \(display.name): built-in or disabled, skipping")
            return
        }

        let current = display.currentBrightness
        let newValue = max(0.0, min(1.0, current + delta))

        debugLog("[Keyboard] \(display.name): \(Int(current * 100))% -> \(Int(newValue * 100))%")

        brightnessController.setBrightness(for: display, to: newValue, manual: true)

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let idx = self.displayManager.displays.firstIndex(where: { $0.id == activeID }) {
                // Switch to manual mode
                self.displayManager.displays[idx].isAutoMode = false
                self.displayManager.displays[idx].currentBrightness = newValue
                self.displayManager.displays[idx].targetBrightness = newValue

                // Persist manual mode + brightness
                var settings = Preferences.shared.settings(for: activeID)
                settings.isAutoMode = false
                settings.manualBrightness = newValue
                Preferences.shared.saveSettings(settings, for: activeID)
            }
        }
    }
}
