import Foundation

/// Persists the player's personal-best distance between app launches.
enum GameState {
    private static let bestDistanceKey = "snowboard.bestDistanceMeters"

    static var bestDistanceMeters: Double {
        get { UserDefaults.standard.double(forKey: bestDistanceKey) }
        set { UserDefaults.standard.set(newValue, forKey: bestDistanceKey) }
    }

    /// Updates the stored best if `distanceMeters` beats it.
    /// Returns `true` if a new personal record was just set.
    @discardableResult
    static func reportRun(distanceMeters: Double) -> Bool {
        guard distanceMeters > bestDistanceMeters else { return false }
        bestDistanceMeters = distanceMeters
        return true
    }
}
