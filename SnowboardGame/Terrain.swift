import SpriteKit

/// Procedurally generates the downhill slope as a pure function of world-x, so the scene
/// never needs to store terrain history - it just samples whatever range of x is
/// currently near the camera.
struct Terrain {
    // MARK: Tunables

    /// World-y dropped per world-x unit - the steady downhill grade.
    static let baseSlope: CGFloat = 0.32
    static let pixelsPerMeter: CGFloat = 18

    private let phase: CGFloat
    private let obstacleSeed: UInt64

    init(phase: CGFloat, obstacleSeed: UInt64) {
        self.phase = phase
        self.obstacleSeed = obstacleSeed
    }

    // MARK: Slope shape

    /// The steady downhill trend line, ignoring bumps. The on-screen "meters descended"
    /// counter is derived only from this, so it always climbs smoothly no matter the
    /// local terrain shape (hills, ramps, etc).
    private func baseAltitude(atX x: CGFloat) -> CGFloat {
        -x * Self.baseSlope
    }

    func metersDescended(atX x: CGFloat) -> Double {
        Double(max(0, x) * Self.baseSlope / Self.pixelsPerMeter)
    }

    /// Rolling hills layered on top of the base grade. Summed sines with unrelated
    /// frequencies give an endless, non-repeating-looking ride out of a closed-form
    /// function - no need to store or generate terrain segments ahead of time.
    private func bumpOffset(atX x: CGFloat) -> CGFloat {
        let a1: CGFloat = 24, f1: CGFloat = 0.0105
        let a2: CGFloat = 13, f2: CGFloat = 0.0235
        let a3: CGFloat = 46, f3: CGFloat = 0.0037
        return a1 * sin(x * f1 + phase)
             + a2 * sin(x * f2 + phase * 1.7)
             + a3 * sin(x * f3 + phase * 0.6)
    }

    func height(atX x: CGFloat) -> CGFloat {
        baseAltitude(atX: x) + bumpOffset(atX: x)
    }

    /// Centered-difference slope. Positive means "descending" - useful for detecting
    /// the lip of a hill where the player should launch into the air.
    func steepness(atX x: CGFloat, sample: CGFloat = 3) -> CGFloat {
        (height(atX: x - sample) - height(atX: x + sample)) / (sample * 2)
    }

    // MARK: Obstacles

    private static let slotWidth: CGFloat = 260

    private func slotIndex(forX x: CGFloat) -> Int {
        Int(floor(x / Self.slotWidth))
    }

    /// Deterministic pseudo-random value in [0, 1) for a slot, seeded per-run so every
    /// playthrough gets a different (but reproducible, and stateless) obstacle layout.
    private func hash(_ slot: Int) -> Double {
        var value = obstacleSeed &+ (UInt64(bitPattern: Int64(slot)) &* 2654435761)
        value ^= value >> 13
        value = value &* 2246822519
        value ^= value >> 16
        return Double(value % 1_000_000) / 1_000_000
    }

    /// Returns the obstacle for this slot, if the deterministic roll says one exists.
    /// The first two slots are always kept clear so the player has time to get moving.
    func obstacle(inSlot slot: Int) -> Obstacle? {
        guard slot > 1 else { return nil }
        let roll = hash(slot)
        guard roll < 0.55 else { return nil }

        let centerX = (CGFloat(slot) + 0.5) * Self.slotWidth
        let isTree = roll < 0.28
        let kind: ObstacleKind = isTree ? .tree : .rock
        let height: CGFloat = isTree
            ? CGFloat(46 + (roll * 977).truncatingRemainder(dividingBy: 28))  // 46...74
            : CGFloat(20 + (roll * 613).truncatingRemainder(dividingBy: 22))  // 20...42
        let width: CGFloat = isTree ? 26 : 34
        return Obstacle(slotIndex: slot, worldX: centerX, width: width, height: height, kind: kind)
    }

    /// All obstacles whose bounds fall (even partially) within the given world-x range.
    func obstacles(inRange range: ClosedRange<CGFloat>) -> [Obstacle] {
        let lowSlot = slotIndex(forX: range.lowerBound) - 1
        let highSlot = slotIndex(forX: range.upperBound) + 1
        guard lowSlot <= highSlot else { return [] }
        return (lowSlot...highSlot).compactMap { obstacle(inSlot: $0) }
    }
}
