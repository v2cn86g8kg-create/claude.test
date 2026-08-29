import SpriteKit
import Foundation

/// A purchasable board/rider color skin.
struct CosmeticItem {
    let id: String
    let name: String
    let price: Int
    let boardColor: SKColor
    let bodyColor: SKColor
}

/// Coin-purchased cosmetics: what's owned, what's equipped, persisted via UserDefaults.
/// `Player` reads `equippedItem` when a run starts to color the board/rider.
enum CosmeticsStore {
    static let items: [CosmeticItem] = [
        CosmeticItem(id: "default", name: "기본", price: 0,
                     boardColor: .systemYellow, bodyColor: .systemRed),
        CosmeticItem(id: "ice", name: "아이스", price: 150,
                     boardColor: .white, bodyColor: SKColor(red: 0.30, green: 0.70, blue: 0.95, alpha: 1)),
        CosmeticItem(id: "lava", name: "라바", price: 150,
                     boardColor: SKColor(red: 0.18, green: 0.18, blue: 0.20, alpha: 1), bodyColor: .systemOrange),
        CosmeticItem(id: "forest", name: "포레스트", price: 200,
                     boardColor: SKColor(red: 0.36, green: 0.25, blue: 0.15, alpha: 1), bodyColor: .systemGreen),
        CosmeticItem(id: "midnight", name: "미드나잇", price: 250,
                     boardColor: SKColor(red: 0.15, green: 0.05, blue: 0.35, alpha: 1), bodyColor: SKColor(red: 0.55, green: 0.25, blue: 0.85, alpha: 1))
    ]

    private static let ownedKey = "cosmetics.owned"
    private static let equippedKey = "cosmetics.equipped"

    static var ownedIDs: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: ownedKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: ownedKey) }
    }

    static var equippedID: String {
        get { UserDefaults.standard.string(forKey: equippedKey) ?? "default" }
        set { UserDefaults.standard.set(newValue, forKey: equippedKey) }
    }

    static var equippedItem: CosmeticItem {
        items.first { $0.id == equippedID } ?? items[0]
    }

    static func isOwned(_ item: CosmeticItem) -> Bool {
        item.price == 0 || ownedIDs.contains(item.id)
    }

    /// Spends coins to unlock `item`. No-op (returns true) if already owned.
    @discardableResult
    static func purchase(_ item: CosmeticItem) -> Bool {
        guard !isOwned(item) else { return true }
        guard CoinWallet.spend(item.price) else { return false }
        var owned = ownedIDs
        owned.insert(item.id)
        ownedIDs = owned
        return true
    }

    static func equip(_ item: CosmeticItem) {
        guard isOwned(item) else { return }
        equippedID = item.id
    }
}
