import Cocoa
import Combine

class DisplayManager: ObservableObject {
    @Published var displays: [DisplayInfo] = []

    private var reconfigCallback: CGDisplayReconfigurationCallBack?

    init() {
        registerForReconfiguration()
        refresh()
    }

    func refresh() {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: 16)
        var displayCount: UInt32 = 0

        guard CGGetActiveDisplayList(16, &displayIDs, &displayCount) == .success else {
            return
        }

        let activeIDs = Array(displayIDs.prefix(Int(displayCount)))
        let prefs = Preferences.shared

        displays = activeIDs.map { displayID in
            let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0
            let name = Self.displayName(for: displayID, isBuiltIn: isBuiltIn)
            let bounds = CGDisplayBounds(displayID)
            let settings = prefs.settings(for: displayID)

            return DisplayInfo(
                id: displayID,
                name: name,
                isBuiltIn: isBuiltIn,
                bounds: bounds,
                isEnabled: settings.isEnabled,
                minBrightness: settings.minBrightness,
                maxBrightness: settings.maxBrightness
            )
        }
    }

    private static func displayName(for displayID: CGDirectDisplayID, isBuiltIn: Bool) -> String {
        // Try to get name from NSScreen
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               screenNumber == displayID {
                return screen.localizedName
            }
        }
        return isBuiltIn ? "Built-in Display" : "External Display (\(displayID))"
    }

    private func registerForReconfiguration() {
        CGDisplayRegisterReconfigurationCallback({ displayID, flags, userInfo in
            guard let userInfo = userInfo else { return }
            let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
            if flags.contains(.addFlag) || flags.contains(.removeFlag) {
                DispatchQueue.main.async {
                    manager.refresh()
                }
            }
        }, Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        CGDisplayRemoveReconfigurationCallback({ _, _, _ in }, nil)
    }
}
