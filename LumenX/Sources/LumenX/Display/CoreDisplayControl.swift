import CoreGraphics

class CoreDisplayControl {
    typealias SetBrightnessFn = @convention(c) (CGDirectDisplayID, Float) -> Void
    typealias GetBrightnessFn = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Void

    private var setBrightnessFunc: SetBrightnessFn?
    private var getBrightnessFunc: GetBrightnessFn?

    init() {
        if let handle = dlopen("/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay", RTLD_LAZY) {
            if let sym = dlsym(handle, "CoreDisplay_Display_SetUserBrightness") {
                setBrightnessFunc = unsafeBitCast(sym, to: SetBrightnessFn.self)
            }
            if let sym = dlsym(handle, "CoreDisplay_Display_GetUserBrightness") {
                getBrightnessFunc = unsafeBitCast(sym, to: GetBrightnessFn.self)
            }
        }
    }

    func set(_ displayID: CGDirectDisplayID, brightness: Float) {
        setBrightnessFunc?(displayID, brightness)
    }

    func get(_ displayID: CGDirectDisplayID) -> Float {
        var value: Float = 0.5
        getBrightnessFunc?(displayID, &value)
        return value
    }
}
