class SmoothingFilter {
    private var smoothedValue: Float?
    var alpha: Float
    /// Don't update if the change is smaller than this
    var deadZone: Float

    init(alpha: Float = 0.3, deadZone: Float = 0.0) {
        self.alpha = alpha
        self.deadZone = deadZone
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
