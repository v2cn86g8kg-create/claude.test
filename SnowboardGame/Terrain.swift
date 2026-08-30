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
    private let chuteSeed: UInt64

    init(phase: CGFloat, chuteSeed: UInt64) {
        self.phase = phase
        self.chuteSeed = chuteSeed
    }

    // MARK: Slope shape

    /// The steady downhill trend line, ignoring bumps. The on-screen "meters descended"
    /// counter is derived only from this, so it always climbs smoothly no matter the
    /// local terrain shape (hills, chutes, etc).
    private func baseAltitude(atX x: CGFloat) -> CGFloat {
        -x * Self.baseSlope
    }

    func metersDescended(atX x: CGFloat) -> Double {
        Double(max(0, x) * Self.baseSlope / Self.pixelsPerMeter)
    }

    /// Rolling hills layered on top of the base grade. Summed sines with unrelated
    /// frequencies give an endless, non-repeating-looking ride out of a closed-form
    /// function. Amplitude ramps up over the first stretch so the run opens on calm,
    /// gentle terrain and only gets rowdy once the player has their bearings.
    private func bumpOffset(atX x: CGFloat) -> CGFloat {
        let a1: CGFloat = 24, f1: CGFloat = 0.0105
        let a2: CGFloat = 13, f2: CGFloat = 0.0235
        let a3: CGFloat = 46, f3: CGFloat = 0.0037
        let raw = a1 * sin(x * f1 + phase)
                + a2 * sin(x * f2 + phase * 1.7)
                + a3 * sin(x * f3 + phase * 0.6)
        return raw * bumpAmplitudeScale(atX: x)
    }

    private func bumpAmplitudeScale(atX x: CGFloat) -> CGFloat {
        let rampDistance: CGFloat = 3500
        return 0.3 + min(1, max(0, x) / rampDistance) * 0.7
    }

    func height(atX x: CGFloat) -> CGFloat {
        baseAltitude(atX: x) + bumpOffset(atX: x) + chuteOffset(atX: x)
    }

    /// Centered-difference slope. Positive means "descending" - useful for detecting
    /// the lip of a hill where the player should launch into the air.
    func steepness(atX x: CGFloat, sample: CGFloat = 3) -> CGFloat {
        (height(atX: x - sample) - height(atX: x + sample)) / (sample * 2)
    }

    // MARK: Steep chutes (telegraphed by a rail beforehand)

    private static let chuteSlotWidth: CGFloat = 2200
    /// No chutes before this point - keeps the opening stretch of the run gentle.
    private static let chuteUnlockX: CGFloat = 1800
    /// Distance over which chute frequency/size ramps up to their full difficulty.
    private static let chuteRampDistance: CGFloat = 8000

    private func chuteSlotIndex(forX x: CGFloat) -> Int {
        Int(floor(x / Self.chuteSlotWidth))
    }

    private func chuteHash(_ slot: Int) -> Double {
        var value = (chuteSeed ^ 0x9E3779B97F4A7C15) &+ (UInt64(bitPattern: Int64(slot)) &* 2246822519)
        value ^= value >> 15
        value = value &* 2654435761
        value ^= value >> 13
        return Double(value % 1_000_000) / 1_000_000
    }

    /// Returns the steep-chute event for this slot, if the deterministic roll says one
    /// exists. Each chute is a bounded, self-contained dip: a flat rail lead-in, a sharp
    /// drop, then a gradual runout back to the normal rolling terrain - never a permanent
    /// change to the mountain, so this stays a cheap O(1) lookup no matter how long a run
    /// goes on.
    func chute(inSlot slot: Int) -> Chute? {
        let center = CGFloat(slot) * Self.chuteSlotWidth
        guard center > Self.chuteUnlockX else { return nil }

        let roll = chuteHash(slot)
        let progress = min(1, (center - Self.chuteUnlockX) / Self.chuteRampDistance)
        let chance = 0.4 + 0.35 * progress
        guard roll < chance else { return nil }

        let dropAmount: CGFloat = 90 + progress * 90 + CGFloat((roll * 4133).truncatingRemainder(dividingBy: 70))
        let railLength: CGFloat = 130
        let dropLength: CGFloat = 70
        let runoutLength: CGFloat = 260 + CGFloat((roll * 777).truncatingRemainder(dividingBy: 140))

        let dropStart = center
        return Chute(
            slotIndex: slot,
            railStart: dropStart - railLength,
            dropStart: dropStart,
            dropBottom: dropStart + dropLength,
            runoutEnd: dropStart + dropLength + runoutLength,
            dropAmount: dropAmount
        )
    }

    /// All chutes whose rail-to-runout span falls (even partially) within the given range.
    func chutes(inRange range: ClosedRange<CGFloat>) -> [Chute] {
        let lowSlot = chuteSlotIndex(forX: range.lowerBound) - 1
        let highSlot = chuteSlotIndex(forX: range.upperBound) + 1
        guard lowSlot <= highSlot else { return [] }
        return (lowSlot...highSlot).compactMap { chute(inSlot: $0) }
    }

    private func chuteOffset(atX x: CGFloat) -> CGFloat {
        let slot = chuteSlotIndex(forX: x)
        var total: CGFloat = 0
        for s in (slot - 1)...(slot + 1) {
            guard let c = chute(inSlot: s) else { continue }
            if x <= c.dropStart {
                continue
            } else if x <= c.dropBottom {
                let t = (x - c.dropStart) / (c.dropBottom - c.dropStart)
                total += -c.dropAmount * smoothstep(t)
            } else if x <= c.runoutEnd {
                let t = (x - c.dropBottom) / (c.runoutEnd - c.dropBottom)
                total += -c.dropAmount * (1 - smoothstep(t))
            }
        }
        return total
    }

    private func smoothstep(_ t: CGFloat) -> CGFloat {
        let c = max(0, min(1, t))
        return c * c * (3 - 2 * c)
    }

}

/// A bounded, self-contained steep drop: a flat "rail" zone where a warning track is
/// drawn (so the player can see it coming), then a sharp drop, then a gradual runout
/// back to the normal terrain.
struct Chute {
    let slotIndex: Int
    let railStart: CGFloat
    let dropStart: CGFloat
    let dropBottom: CGFloat
    let runoutEnd: CGFloat
    let dropAmount: CGFloat
}
