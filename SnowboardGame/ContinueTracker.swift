import Foundation

/// Tracks the once-per-calendar-day free continue offered on the game-over screen.
enum ContinueTracker {
    private static let lastUsedDayKey = "continue.lastUsedDay"

    private static var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter.string(from: Date())
    }

    static func hasFreeContinueToday() -> Bool {
        UserDefaults.standard.string(forKey: lastUsedDayKey) != todayKey
    }

    static func consumeFreeContinue() {
        UserDefaults.standard.set(todayKey, forKey: lastUsedDayKey)
    }
}
