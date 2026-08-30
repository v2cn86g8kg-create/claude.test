import UIKit

/// Centralizes every haptic the game fires, so the feel of each event can be retuned in
/// one place later without hunting through gameplay code. Every call respects the
/// vibration toggle in Settings.
enum Haptics {
    /// A light tap when the rider lands cleanly off a jump.
    static func landing() {
        guard SettingsStore.vibrationEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Fired when a run ends - a bad landing where the body hits the snow instead of
    /// the board.
    static func crash() {
        guard SettingsStore.vibrationEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    /// Fired for a landed combo-bar trick tap. Each judgement gets a distinct feel for
    /// now (placeholder tuning) - swap these out once the feel is designed for real.
    static func trick(_ judgement: TrickJudgement) {
        guard SettingsStore.vibrationEnabled else { return }
        switch judgement {
        case .perfect:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .great:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .good:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .fail:
            break
        }
    }
}
