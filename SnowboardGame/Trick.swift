import CoreGraphics
import Foundation

/// The air tricks the player can pull off. Which one triggers on a tap depends on how
/// much air (height above the slope) the player has gained during the current jump.
enum AirTrick: CaseIterable {
    case grab
    case spin360
    case backflip

    var displayName: String {
        switch self {
        case .grab: return "GRAB!"
        case .spin360: return "360 SPIN!"
        case .backflip: return "BACKFLIP!"
        }
    }

    var scoreBonus: Int {
        switch self {
        case .grab: return 10
        case .spin360: return 30
        case .backflip: return 60
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

    /// Picks a trick tier from how many meters of air the player currently has.
    static func forAirHeight(meters: Double) -> AirTrick {
        switch meters {
        case ..<3:
            return .grab
        case 3..<7:
            return .spin360
        default:
            return .backflip
        }
    }
}
