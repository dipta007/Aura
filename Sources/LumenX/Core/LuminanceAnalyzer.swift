import CoreGraphics

class LuminanceAnalyzer {
    func averageLuminance(of image: CGImage) -> Float {
        guard let data = image.dataProvider?.data,
              let ptr = CFDataGetBytePtr(data) else { return 0.5 }

        let bytesPerPixel = image.bitsPerPixel / 8
        let totalPixels = image.width * image.height

        guard totalPixels > 0, bytesPerPixel >= 3 else { return 0.5 }

        var totalLuminance: Float = 0

        for i in 0..<totalPixels {
            let offset = i * bytesPerPixel
            let r = Float(ptr[offset]) / 255.0
            let g = Float(ptr[offset + 1]) / 255.0
            let b = Float(ptr[offset + 2]) / 255.0

            // Perceived luminance (ITU-R BT.709)
            totalLuminance += 0.2126 * r + 0.7152 * g + 0.0722 * b
        }

        return totalLuminance / Float(totalPixels)
    }
}
