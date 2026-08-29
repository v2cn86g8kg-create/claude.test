import Foundation

/// The one real-money purchase in the prototype: removing ads. There is no StoreKit
/// product wired up yet - `purchaseRemoveAds` is a stand-in that succeeds immediately
/// so the rest of the app (Shop UI, the game-over continue flow) can be built and
/// tested against a real on/off state today.
///
/// To go live: register a non-consumable IAP (e.g. "remove_ads") in App Store Connect,
/// then replace the body of `purchaseRemoveAds` with a real StoreKit 2 purchase
/// (`Product.products(for:)` -> `product.purchase()`), setting `isAdsRemoved = true`
/// only once that purchase actually verifies.
enum PurchaseStore {
    private static let adsRemovedKey = "purchase.adsRemoved"

    static var isAdsRemoved: Bool {
        get { UserDefaults.standard.bool(forKey: adsRemovedKey) }
        set { UserDefaults.standard.set(newValue, forKey: adsRemovedKey) }
    }

    /// Placeholder display price until a real StoreKit product supplies a localized one.
    static let removeAdsDisplayPrice = "₩3,900"

    static func purchaseRemoveAds(completion: @escaping (Bool) -> Void) {
        isAdsRemoved = true
        completion(true)
    }
}
