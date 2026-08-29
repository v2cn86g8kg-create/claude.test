import SpriteKit

/// First scene shown on launch: logo + a progress bar, then hands off to `LobbyScene`.
/// There's no heavy asset loading to actually wait on yet, so the bar just animates
/// over a fixed duration - swap `advance(dt:)` for real progress once there's something
/// to load (texture atlases, audio, etc).
final class LoadingScene: SKScene {
    private let barWidth: CGFloat = 240
    private let barHeight: CGFloat = 14
    private let track = SKShapeNode()
    private let fill = SKShapeNode()

    private let duration: TimeInterval = 1.4
    private var elapsed: TimeInterval = 0
    private var lastUpdateTime: TimeInterval?
    private var didTransition = false

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.09, green: 0.12, blue: 0.20, alpha: 1)
        scaleMode = .resizeFill

        let logo = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        logo.text = "SNOWBOARD RUSH"
        logo.fontSize = 30
        logo.fontColor = .white
        logo.position = CGPoint(x: 0, y: 30)
        addChild(logo)

        track.path = roundedBar(width: barWidth)
        track.fillColor = SKColor(white: 1, alpha: 0.15)
        track.strokeColor = SKColor(white: 1, alpha: 0.4)
        track.lineWidth = 1.5
        track.position = CGPoint(x: 0, y: -20)
        addChild(track)

        fill.fillColor = .systemYellow
        fill.strokeColor = .clear
        fill.position = CGPoint(x: 0, y: -20)
        addChild(fill)

        updateFill(progress: 0)
    }

    override func update(_ currentTime: TimeInterval) {
        guard !didTransition else { return }
        let dt = min(lastUpdateTime.map { currentTime - $0 } ?? (1.0 / 60.0), 1.0 / 30.0)
        lastUpdateTime = currentTime

        elapsed += dt
        let progress = min(1, CGFloat(elapsed / duration))
        updateFill(progress: progress)

        if progress >= 1 {
            goToLobby()
        }
    }

    private func updateFill(progress: CGFloat) {
        let w = max(0.001, barWidth * progress)
        fill.path = roundedBar(width: w, leftAnchored: true)
    }

    /// A rounded bar centered at the origin, or (when `leftAnchored`) anchored to the
    /// left edge of the full `barWidth` track so a partial fill grows rightward.
    private func roundedBar(width: CGFloat, leftAnchored: Bool = false) -> CGPath {
        let x = leftAnchored ? -barWidth / 2 : -width / 2
        return CGPath(
            roundedRect: CGRect(x: x, y: -barHeight / 2, width: width, height: barHeight),
            cornerWidth: barHeight / 2,
            cornerHeight: barHeight / 2,
            transform: nil
        )
    }

    private func goToLobby() {
        guard !didTransition, let view = view else { return }
        didTransition = true
        let lobby = LobbyScene()
        lobby.size = size
        lobby.scaleMode = scaleMode
        view.presentScene(lobby, transition: SKTransition.fade(withDuration: 0.4))
    }
}
