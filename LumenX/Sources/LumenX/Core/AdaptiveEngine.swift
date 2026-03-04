import Combine
import CoreGraphics
import Foundation

class AdaptiveEngine: ObservableObject {
    @Published var isRunning: Bool = true {
        didSet {
            if isRunning { start() } else { stop() }
        }
    }

    private let displayManager: DisplayManager
    private let capturer = ScreenCapturer()
    private let analyzer = LuminanceAnalyzer()
    private let brightnessController = BrightnessController()

    private var filters: [CGDirectDisplayID: SmoothingFilter] = [:]
    private var timer: Timer?

    var sampleInterval: TimeInterval = Constants.defaultSampleInterval

    @Published var sensitivity: Float = Constants.defaultSensitivity

    init(displayManager: DisplayManager) {
        self.displayManager = displayManager
    }

    func start() {
        guard timer == nil else { return }
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: sampleInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // Run immediately on start
        tick()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        // Restore gamma tables
        for _ in displayManager.displays {
            CGDisplayRestoreColorSyncSettings()
        }
    }

    private func tick() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            for i in 0..<self.displayManager.displays.count {
                let display = self.displayManager.displays[i]
                guard display.isEnabled else { continue }

                // 1. Capture this display's content (downsampled)
                guard let image = self.capturer.captureAndDownsample(display.id) else { continue }

                // 2. Calculate average luminance
                let luminance = self.analyzer.averageLuminance(of: image)

                // 3. Map luminance to desired brightness (inverse relationship)
                let rawTarget = self.mapLuminanceToBrightness(luminance)

                // 4. Apply smoothing
                let filter = self.filters[display.id] ?? {
                    let f = SmoothingFilter(alpha: Constants.defaultSmoothingAlpha)
                    self.filters[display.id] = f
                    return f
                }()
                let smoothedTarget = filter.update(newValue: rawTarget)

                // 5. Apply brightness
                var updated = display
                updated.targetBrightness = smoothedTarget
                self.brightnessController.setBrightness(for: updated, to: smoothedTarget)

                // Update the display info on main thread
                DispatchQueue.main.async {
                    if i < self.displayManager.displays.count {
                        self.displayManager.displays[i].targetBrightness = smoothedTarget
                        self.displayManager.displays[i].currentBrightness = smoothedTarget
                    }
                }
            }
        }
    }

    /// Core mapping: content luminance → display brightness
    /// Bright content → lower brightness, dark content → higher brightness
    private func mapLuminanceToBrightness(_ luminance: Float) -> Float {
        let midpoint: Float = 0.5
        let steepness: Float = 3.0 * sensitivity

        let x = luminance - midpoint
        let sigmoid = 1.0 / (1.0 + exp(steepness * x))

        let minOut: Float = 0.2
        let maxOut: Float = 0.95
        return minOut + sigmoid * (maxOut - minOut)
    }
}
