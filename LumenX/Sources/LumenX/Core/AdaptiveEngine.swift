import Combine
import CoreGraphics
import Foundation

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

class AdaptiveEngine: ObservableObject {
    @Published var isRunning: Bool = false {
        didSet {
            guard isRunning != oldValue else { return }
            if isRunning { start() } else { stop() }
        }
    }

    private let displayManager: DisplayManager
    private let capturer = ScreenCapturer()
    private let analyzer = LuminanceAnalyzer()
    let brightnessController = BrightnessController()

    private var filters: [CGDirectDisplayID: SmoothingFilter] = [:]
    private var lastAppliedBrightness: [CGDirectDisplayID: Float] = [:]
    private var timer: Timer?

    var sampleInterval: TimeInterval = Constants.defaultSampleInterval

    @Published var sensitivity: Float = Constants.defaultSensitivity

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }

    func start() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        isRunning = true
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func tick() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            debugLog("[LumenX] tick: \(self.displayManager.displays.count) displays, sensitivity=\(self.sensitivity)")

            for i in 0..<self.displayManager.displays.count {
                let display = self.displayManager.displays[i]
                guard display.isEnabled else {
                    debugLog("[LumenX] display \(display.name): disabled, skipping")
                    continue
                }
                guard display.isAutoMode else {
                    debugLog("[LumenX] display \(display.name): manual mode, skipping")
                    continue
                }

                // 1. Capture this display's content (downsampled)
                guard let image = self.capturer.captureAndDownsample(display.id) else {
                    debugLog("[LumenX] display \(display.name): capture FAILED (nil)")
                    continue
                }

                // 2. Calculate average luminance (no gamma compensation needed with DDC)
                let luminance = self.analyzer.averageLuminance(of: image)

                // 3. Map luminance to desired brightness using per-display min/max
                let rawTarget = self.mapLuminanceToBrightness(luminance, min: display.minBrightness, max: display.maxBrightness)

                // 4. Apply smoothing — jump fast for large changes, smooth for small
                let filter = self.filters[display.id] ?? {
                    let f = SmoothingFilter()
                    self.filters[display.id] = f
                    return f
                }()
                let lastValue = self.lastAppliedBrightness[display.id] ?? rawTarget
                let delta = abs(rawTarget - lastValue)
                // Large change (>15%): jump almost instantly; small: smooth gently
                let alpha: Float = delta > 0.15 ? 0.85 : (0.1 + self.sensitivity * 0.5)
                filter.alpha = alpha
                let smoothedTarget = filter.update(newValue: rawTarget)

                // 5. Only apply brightness if the change is significant (>2%)
                let lastApplied = self.lastAppliedBrightness[display.id] ?? 1.0
                let changed = abs(smoothedTarget - lastApplied) > 0.01

                debugLog("[LumenX] \(display.name): luminance=\(luminance) target=\(rawTarget) smoothed=\(smoothedTarget) applying=\(changed)")

                if changed {
                    var updated = display
                    updated.targetBrightness = smoothedTarget
                    self.brightnessController.setBrightness(for: updated, to: smoothedTarget)
                    self.lastAppliedBrightness[display.id] = smoothedTarget
                }

                // Update the display info on main thread
                let displayID = display.id
                DispatchQueue.main.async {
                    if let index = self.displayManager.displays.firstIndex(where: { $0.id == displayID }) {
                        self.displayManager.displays[index].targetBrightness = smoothedTarget
                        self.displayManager.displays[index].currentBrightness = smoothedTarget
                    }
                }
            }
        }
    }

    /// Core mapping: content luminance → display brightness
    /// Maps into the display's [min, max] range
    /// When user sets manual brightness, that becomes max (baseline)
    private func mapLuminanceToBrightness(_ luminance: Float, min floor: Float, max ceiling: Float) -> Float {
        let inverted = 1.0 - luminance
        let curved = pow(inverted, 0.6)
        return floor + curved * (ceiling - floor)
    }
}
