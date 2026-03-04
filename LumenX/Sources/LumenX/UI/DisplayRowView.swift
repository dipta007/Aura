import SwiftUI

struct DisplayRowView: View {
    let display: DisplayInfo
    @ObservedObject var displayManager: DisplayManager
    let brightnessController: BrightnessController

    @State private var isEnabled: Bool = true
    @State private var isAutoMode: Bool = true
    @State private var manualBrightness: Float = 0.5
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
                VStack(alignment: .leading, spacing: 8) {
                    // Auto/Manual toggle
                    Picker("Mode", selection: $isAutoMode) {
                        Text("Auto").tag(true)
                        Text("Manual").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: isAutoMode) { newValue in
                        if newValue {
                            // Switching to auto: use manual brightness as max baseline
                            maxBrightness = manualBrightness
                        } else {
                            // Switching to manual: use current brightness
                            manualBrightness = display.currentBrightness
                            applyManualBrightness()
                        }
                        updateDisplaySettings()
                    }

                    if !isAutoMode {
                        // Manual brightness slider
                        HStack {
                            Image(systemName: "sun.min")
                                .font(.caption2)
                            Slider(value: $manualBrightness, in: 0.0...1.0)
                                .onChange(of: manualBrightness) { _ in
                                    applyManualBrightness()
                                    updateDisplaySettings()
                                }
                            Image(systemName: "sun.max")
                                .font(.caption2)
                            Text("\(Int(manualBrightness * 100))%")
                                .font(.caption2)
                                .frame(width: 35)
                        }
                    } else {
                        // Auto mode: min/max sliders
                        HStack {
                            Text("Min")
                                .font(.caption2)
                                .frame(width: 30)
                            Slider(value: $minBrightness, in: 0.0...0.5)
                                .onChange(of: minBrightness) { _ in updateDisplaySettings() }
                            Text("\(Int(minBrightness * 100))%")
                                .font(.caption2)
                                .frame(width: 35)
                        }
                        HStack {
                            Text("Max")
                                .font(.caption2)
                                .frame(width: 30)
                            Slider(value: $maxBrightness, in: 0.1...1.0)
                                .onChange(of: maxBrightness) { _ in updateDisplaySettings() }
                            Text("\(Int(maxBrightness * 100))%")
                                .font(.caption2)
                                .frame(width: 35)
                        }
                    }
                }
                .padding(.leading, 24)
            }
        }
        .onAppear {
            let settings = Preferences.shared.settings(for: display.id)
            isEnabled = settings.isEnabled
            isAutoMode = settings.isAutoMode
            manualBrightness = settings.manualBrightness
            minBrightness = settings.minBrightness
            maxBrightness = settings.maxBrightness
        }
        // Sync when display model changes externally (keyboard, auto engine)
        .onChange(of: display.isAutoMode) { newValue in
            isAutoMode = newValue
            if !newValue {
                let settings = Preferences.shared.settings(for: display.id)
                manualBrightness = settings.manualBrightness
            }
        }
        .onChange(of: display.currentBrightness) { newValue in
            if !isAutoMode {
                manualBrightness = newValue
            }
        }
    }

    private var brightnessColor: Color {
        let b = Double(isAutoMode ? display.targetBrightness : manualBrightness)
        return Color(red: b, green: b, blue: 0.2 + b * 0.8)
    }

    private func applyManualBrightness() {
        if let index = displayManager.displays.firstIndex(where: { $0.id == display.id }) {
            let displayInfo = displayManager.displays[index]
            brightnessController.setBrightness(for: displayInfo, to: manualBrightness, manual: true)
            displayManager.displays[index].currentBrightness = manualBrightness
            displayManager.displays[index].targetBrightness = manualBrightness
        }
    }

    private func updateDisplaySettings() {
        let settings = Preferences.DisplaySettings(
            isEnabled: isEnabled,
            isAutoMode: isAutoMode,
            manualBrightness: manualBrightness,
            minBrightness: minBrightness,
            maxBrightness: maxBrightness
        )
        Preferences.shared.saveSettings(settings, for: display.id)

        if let index = displayManager.displays.firstIndex(where: { $0.id == display.id }) {
            displayManager.displays[index].isEnabled = isEnabled
            displayManager.displays[index].isAutoMode = isAutoMode
            displayManager.displays[index].minBrightness = minBrightness
            displayManager.displays[index].maxBrightness = maxBrightness
        }
    }
}
