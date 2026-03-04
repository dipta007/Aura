import CoreGraphics

class BrightnessController {
    private let coreDisplay = CoreDisplayControl()
    private let ddc = DDCBrightnessControl()

    func setBrightness(for display: DisplayInfo, to value: Float) {
        let clamped = max(display.minBrightness, min(display.maxBrightness, value))

        if display.isBuiltIn {
            coreDisplay.set(display.id, brightness: clamped)
        } else {
            // Try DDC first, fall back to gamma overlay
            let ddcValue = UInt16(clamped * 100)
            if !ddc.setBrightness(display.id, value: ddcValue) {
                setSoftwareBrightness(display.id, brightness: clamped)
            }
        }
    }

    func getCurrentBrightness(for display: DisplayInfo) -> Float {
        if display.isBuiltIn {
            return coreDisplay.get(display.id)
        } else {
            if let ddcValue = ddc.getBrightness(display.id) {
                return Float(ddcValue) / 100.0
            }
            return 0.5
        }
    }

    private func setSoftwareBrightness(_ displayID: CGDirectDisplayID, brightness: Float) {
        let tableSize: Int = 256
        var redTable = [CGGammaValue](repeating: 0, count: tableSize)
        var greenTable = [CGGammaValue](repeating: 0, count: tableSize)
        var blueTable = [CGGammaValue](repeating: 0, count: tableSize)

        for i in 0..<tableSize {
            let value = CGGammaValue(Float(i) / Float(tableSize - 1) * brightness)
            redTable[i] = value
            greenTable[i] = value
            blueTable[i] = value
        }

        CGSetDisplayTransferByTable(displayID, UInt32(tableSize), &redTable, &greenTable, &blueTable)
    }
}
