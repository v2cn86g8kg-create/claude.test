import SpriteKit

/// A rewarded-ad backend. Swap `AdsManager.provider` for a real implementation once an
/// ad network account exists - the game only ever talks to this protocol, never to a
/// specific SDK.
protocol RewardedAdProviding {
    /// Shows a rewarded ad on top of `scene`. `completion(true)` means the viewer
    /// watched it through and should get the reward; `completion(false)` means it was
    /// skipped, failed to load, or errored.
    func present(in scene: SKScene, completion: @escaping (Bool) -> Void)
}

/// Central place the game asks for rewarded ads. Defaults to a simulated ad so the
/// continue flow is fully testable without a real ad network account.
///
/// To go live with e.g. Google Mobile Ads: add the GoogleMobileAds SPM package, wrap a
/// `GADRewardedAd` in a type conforming to `RewardedAdProviding`, and set
/// `AdsManager.provider = GoogleAdMobRewardedProvider()` at launch (also add
/// `GADApplicationIdentifier` to Info.plist and request tracking/consent per Apple and
/// Google's requirements). Nothing else in the game needs to change.
enum AdsManager {
    static var provider: RewardedAdProviding = MockRewardedAdProvider()

    static func showRewardedAd(in scene: SKScene, completion: @escaping (Bool) -> Void) {
        provider.present(in: scene, completion: completion)
    }
}

/// Simulates a rewarded ad: a few seconds of a full-screen "ad" with a countdown, then
/// always rewards. Good enough to build and test the whole continue flow against.
final class MockRewardedAdProvider: RewardedAdProviding {
    func present(in scene: SKScene, completion: @escaping (Bool) -> Void) {
        let overlay = AdMockOverlay(sceneSize: scene.size) {
            completion(true)
        }
        overlay.zPosition = 1000
        if let camera = scene.camera {
            camera.addChild(overlay)
        } else {
            scene.addChild(overlay)
        }
        overlay.play()
    }
}

/// The simulated ad's visuals: a dark full-screen panel with a shrinking countdown,
/// standing in for a real rewarded-video placement.
private final class AdMockOverlay: SKNode {
    private let onFinished: () -> Void
    private let countdownLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    private let totalSeconds = 5
    private var remaining: Int

    init(sceneSize: CGSize, onFinished: @escaping () -> Void) {
        self.onFinished = onFinished
        self.remaining = totalSeconds
        super.init()

        let dim = SKShapeNode(rectOf: sceneSize)
        dim.fillColor = .black
        dim.strokeColor = .clear
        addChild(dim)

        let title = SKLabelNode(fontNamed: "AvenirNext-Bold")
        title.text = "광고 재생 중 (테스트)"
        title.fontSize = 20
        title.fontColor = SKColor(white: 1, alpha: 0.85)
        title.position = CGPoint(x: 0, y: 34)
        addChild(title)

        countdownLabel.fontSize = 46
        countdownLabel.fontColor = .systemYellow
        countdownLabel.text = "\(remaining)"
        addChild(countdownLabel)

        let subtitle = SKLabelNode(fontNamed: "AvenirNext-Bold")
        subtitle.text = "잠시 후 이어하기가 시작됩니다"
        subtitle.fontSize = 15
        subtitle.fontColor = SKColor(white: 1, alpha: 0.6)
        subtitle.position = CGPoint(x: 0, y: -40)
        addChild(subtitle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func play() {
        let tick = SKAction.sequence([
            SKAction.wait(forDuration: 1.0),
            SKAction.run { [weak self] in
                guard let self else { return }
                self.remaining -= 1
                self.countdownLabel.text = "\(max(0, self.remaining))"
            }
        ])
        let finish = SKAction.run { [weak self] in
            guard let self else { return }
            self.removeFromParent()
            self.onFinished()
        }
        run(SKAction.sequence([SKAction.repeat(tick, count: totalSeconds), finish]))
    }
}
