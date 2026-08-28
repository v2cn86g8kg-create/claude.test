import CoreGraphics
import Foundation

/// The air tricks in a combo, always attempted in this order: land the grab, then the
/// combo offers the spin, then the backflip. Each step is judged by `HUD`'s timing bar.
enum AirTrick: CaseIterable {
    case grab
    case spin360
    case backflip

    /// Short label shown while this step of the combo is active.
    var shortName: String {
        switch self {
        case .grab: return "GRAB"
        case .spin360: return "SPIN"
        case .backflip: return "BACKFLIP"
        }
    }

    /// Base score for landing this step at a Perfect timing (see `TrickJudgement`).
    var scoreBonus: Int {
        switch self {
        case .grab: return 20
        case .spin360: return 50
        case .backflip: return 100
        }
    }

    /// Rotation (in radians) the player node spins through while performing the trick.
    var rotation: CGFloat {
        switch self {
        case .grab: return .pi / 5          // small tweak/grab pose, not a full flip
        case .spin360: return .pi * 2       // one full spin
        case .backflip: return .pi * 2 * 1.5 // bigger, faster multi-rotation flip
        }
    }

    var animationDuration: TimeInterval {
        switch self {
        case .grab: return 0.35
        case .spin360: return 0.55
        case .backflip: return 0.8
        }
    }
}

/// How closely a combo-bar tap landed on the sweet spot.
enum TrickJudgement: Equatable {
    case perfect
    case great
    case good
    case fail

    var scoreMultiplier: Double {
        switch self {
        case .perfect: return 1.0
        case .great: return 0.7
        case .good: return 0.4
        case .fail: return 0
        }
    }

    var label: String {
        switch self {
        case .perfect: return "PERFECT!"
        case .great: return "GREAT!"
        case .good: return "GOOD"
        case .fail: return "MISS"
        }
    }

    /// Whether the combo continues to the next step after this judgement.
    var continuesCombo: Bool { self != .fail }
}
