import SwiftUI
import CoreGraphics

class Preferences: ObservableObject {
    static let shared = Preferences()

    @AppStorage("isEnabled") var isEnabled: Bool = true
    @AppStorage("sampleInterval") var sampleInterval: Double = Constants.defaultSampleInterval
    @AppStorage("sensitivity") var sensitivity: Double = Double(Constants.defaultSensitivity)
    @AppStorage("smoothingAlpha") var smoothingAlpha: Double = Double(Constants.defaultSmoothingAlpha)
    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    @AppStorage("displaySettingsData") var displaySettingsData: Data = Data()

    struct DisplaySettings: Codable {
        var isEnabled: Bool = true
        var minBrightness: Float = Constants.defaultMinBrightness
        var maxBrightness: Float = Constants.defaultMaxBrightness
    }

    func settings(for displayID: CGDirectDisplayID) -> DisplaySettings {
        guard let dict = try? JSONDecoder().decode([String: DisplaySettings].self, from: displaySettingsData),
              let settings = dict["\(displayID)"] else {
            return DisplaySettings()
        }
        return settings
    }

    func saveSettings(_ settings: DisplaySettings, for displayID: CGDirectDisplayID) {
        var dict = (try? JSONDecoder().decode([String: DisplaySettings].self, from: displaySettingsData)) ?? [:]
        dict["\(displayID)"] = settings
        displaySettingsData = (try? JSONEncoder().encode(dict)) ?? Data()
    }
}
