import CoreGraphics

struct DisplayInfo: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let isBuiltIn: Bool
    let bounds: CGRect
    var currentBrightness: Float = 0.5
    var targetBrightness: Float = 0.5
    var isEnabled: Bool = true
    var minBrightness: Float = Constants.defaultMinBrightness
    var maxBrightness: Float = Constants.defaultMaxBrightness
}
