import SwiftUI

struct MenuBarView: View {
    @ObservedObject var engine: AdaptiveEngine
    @ObservedObject var displayManager: DisplayManager
    @ObservedObject var prefs: Preferences = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with global toggle
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                Text("LumenX")
                    .font(.headline)
                Spacer()
                Toggle("", isOn: $engine.isRunning)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            Divider()

            // Per-display controls
            ForEach(displayManager.displays) { display in
                DisplayRowView(display: display, displayManager: displayManager)
            }

            Divider()

            // Global sensitivity
            VStack(alignment: .leading, spacing: 4) {
                Text("Sensitivity")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $engine.sensitivity, in: 0.1...1.0)
            }

            // Sample interval
            VStack(alignment: .leading, spacing: 4) {
                Text("Update interval: \(String(format: "%.1fs", prefs.sampleInterval))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Slider(value: $prefs.sampleInterval, in: 0.5...5.0, step: 0.5)
            }

            Divider()

            Button("Quit LumenX") {
                NSApplication.shared.terminate(nil)
            }
            .foregroundColor(.red)
        }
        .padding()
        .frame(width: 300)
    }
}
