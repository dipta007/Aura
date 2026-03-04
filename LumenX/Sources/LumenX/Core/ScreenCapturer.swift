import CoreGraphics

class ScreenCapturer {
    func captureAndDownsample(_ displayID: CGDirectDisplayID, size: Int = Constants.downsampleSize) -> CGImage? {
        guard let fullImage = CGDisplayCreateImage(displayID) else { return nil }

        guard let context = CGContext(
            data: nil,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: size * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        context.interpolationQuality = .low
        context.draw(fullImage, in: CGRect(x: 0, y: 0, width: size, height: size))
        return context.makeImage()
    }
}
