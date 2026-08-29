import Foundation

/// Persists the settings-popup preferences (volumes + vibration) between launches.
/// There's no audio system wired up yet, so the volume values are just stored for
/// now - vibration is real, driving the crash haptic in `GameScene`.
enum SettingsStore {
    private static let masterKey = "settings.masterVolume"
    private static let effectKey = "settings.effectVolume"
    private static let sfxKey = "settings.sfxVolume"
    private static let vibrationKey = "settings.vibrationEnabled"

    static var masterVolume: Float {
        get { storedFloat(masterKey, default: 1.0) }
        set { UserDefaults.standard.set(newValue, forKey: masterKey) }
    }

    static var effectVolume: Float {
        get { storedFloat(effectKey, default: 1.0) }
        set { UserDefaults.standard.set(newValue, forKey: effectKey) }
    }

    static var sfxVolume: Float {
        get { storedFloat(sfxKey, default: 1.0) }
        set { UserDefaults.standard.set(newValue, forKey: sfxKey) }
    }

    static var vibrationEnabled: Bool {
        get {
            guard UserDefaults.standard.object(forKey: vibrationKey) != nil else { return true }
            return UserDefaults.standard.bool(forKey: vibrationKey)
        }
        set { UserDefaults.standard.set(newValue, forKey: vibrationKey) }
    }

    private static func storedFloat(_ key: String, default defaultValue: Float) -> Float {
        guard UserDefaults.standard.object(forKey: key) != nil else { return defaultValue }
        return UserDefaults.standard.float(forKey: key)
    }
}
