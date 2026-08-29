import Foundation

/// The player's in-game coin balance (soft currency, spent in the Shop on cosmetics).
/// Not real money - separate from `PurchaseStore`, which tracks the real-money
/// "remove ads" purchase.
enum CoinWallet {
    private static let key = "wallet.coins"

    static var balance: Int {
        get { UserDefaults.standard.integer(forKey: key) }
        set { UserDefaults.standard.set(max(0, newValue), forKey: key) }
    }

    static func add(_ amount: Int) {
        guard amount > 0 else { return }
        balance += amount
    }

    @discardableResult
    static func spend(_ amount: Int) -> Bool {
        guard amount > 0, balance >= amount else { return false }
        balance -= amount
        return true
    }

    /// Coins earned for a finished run - simple flat rate off distance, tuned so a
    /// typical run buys into the cheaper cosmetics after a handful of plays.
    static func reward(forDistanceMeters distance: Double) -> Int {
        Int(distance / 4)
    }
}
