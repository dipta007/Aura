import SwiftUI

struct SettingsView: View {
    @ObservedObject var prefs: Preferences = .shared

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $prefs.launchAtLogin)

            VStack(alignment: .leading) {
                Text("Sample Interval: \(String(format: "%.1fs", prefs.sampleInterval))")
                Slider(value: $prefs.sampleInterval, in: 0.5...5.0, step: 0.5)
            }

            VStack(alignment: .leading) {
                Text("Sensitivity: \(String(format: "%.0f%%", prefs.sensitivity * 100))")
                Slider(value: $prefs.sensitivity, in: 0.1...1.0)
            }

            VStack(alignment: .leading) {
                Text("Smoothing: \(String(format: "%.0f%%", prefs.smoothingAlpha * 100))")
                Slider(value: $prefs.smoothingAlpha, in: 0.05...0.5)
            }
        }
        .padding()
        .frame(width: 300)
    }
}
