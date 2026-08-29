import CoreMotion
import CoreGraphics

/// Wraps CoreMotion to expose a smoothed, drift-free left/right tilt signal for the
/// background's tilt-parallax effect. Reads the device's gravity vector (not raw
/// gyro integration, which drifts) - `gravity.x` is the standard, stable proxy every
/// tilt-controlled iOS game uses for "how far left/right is the phone tilted". Purely
/// cosmetic: gameplay never reads this.
final class TiltInput {
    private let motionManager = CMMotionManager()
    private let smoothing: CGFloat = 0.12

    /// Smoothed tilt, roughly -1 (tilted left) ... +1 (tilted right).
    private(set) var tiltX: CGFloat = 0

    var isAvailable: Bool { motionManager.isDeviceMotionAvailable }

    func start() {
        guard motionManager.isDeviceMotionAvailable, !motionManager.isDeviceMotionActive else { return }
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let raw = CGFloat(motion.gravity.x)
            self.tiltX += (raw - self.tiltX) * self.smoothing
        }
    }

    func stop() {
        guard motionManager.isDeviceMotionActive else { return }
        motionManager.stopDeviceMotionUpdates()
    }
}
