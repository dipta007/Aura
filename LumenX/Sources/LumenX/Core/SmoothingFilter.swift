class SmoothingFilter {
    private var smoothedValue: Float?
    var alpha: Float

    init(alpha: Float = Constants.defaultSmoothingAlpha) {
        self.alpha = alpha
    }

    func update(newValue: Float) -> Float {
        guard let current = smoothedValue else {
            smoothedValue = newValue
            return newValue
        }
        let result = current + alpha * (newValue - current)
        smoothedValue = result
        return result
    }

    func reset() {
        smoothedValue = nil
    }
}
