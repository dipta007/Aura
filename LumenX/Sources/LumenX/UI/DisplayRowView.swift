import SwiftUI

struct DisplayRowView: View {
    let display: DisplayInfo
    @ObservedObject var displayManager: DisplayManager

    @State private var isEnabled: Bool = true
    @State private var minBrightness: Float = Constants.defaultMinBrightness
    @State private var maxBrightness: Float = Constants.defaultMaxBrightness
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: display.isBuiltIn ? "laptopcomputer" : "display")
                Text(display.name)
                    .font(.subheadline.weight(.medium))
                Spacer()

                Circle()
                    .fill(brightnessColor)
                    .frame(width: 8, height: 8)

                Toggle("", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
                    .onChange(of: isEnabled) { newValue in
                        updateDisplaySettings()
                    }

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.plain)
            }

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Min")
                            .font(.caption2)
                            .frame(width: 30)
                        Slider(value: $minBrightness, in: 0.05...0.5)
                            .onChange(of: minBrightness) { _ in updateDisplaySettings() }
                        Text("\(Int(minBrightness * 100))%")
                            .font(.caption2)
                            .frame(width: 35)
                    }
                    HStack {
                        Text("Max")
                            .font(.caption2)
                            .frame(width: 30)
                        Slider(value: $maxBrightness, in: 0.5...1.0)
                            .onChange(of: maxBrightness) { _ in updateDisplaySettings() }
                        Text("\(Int(maxBrightness * 100))%")
                            .font(.caption2)
                            .frame(width: 35)
                    }
                }
                .padding(.leading, 24)
            }
        }
        .onAppear {
            let settings = Preferences.shared.settings(for: display.id)
            isEnabled = settings.isEnabled
            minBrightness = settings.minBrightness
            maxBrightness = settings.maxBrightness
        }
    }

    private var brightnessColor: Color {
        let b = Double(display.targetBrightness)
        return Color(red: b, green: b, blue: 0.2 + b * 0.8)
    }

    private func updateDisplaySettings() {
        let settings = Preferences.DisplaySettings(
            isEnabled: isEnabled,
            minBrightness: minBrightness,
            maxBrightness: maxBrightness
        )
        Preferences.shared.saveSettings(settings, for: display.id)

        // Update display in manager
        if let index = displayManager.displays.firstIndex(where: { $0.id == display.id }) {
            displayManager.displays[index].isEnabled = isEnabled
            displayManager.displays[index].minBrightness = minBrightness
            displayManager.displays[index].maxBrightness = maxBrightness
        }
    }
}
