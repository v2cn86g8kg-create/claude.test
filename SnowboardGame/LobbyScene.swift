import SpriteKit
import UIKit

/// Title/waiting-room screen shown after loading: a "게임 시작" button bottom-center, a
/// settings button top-right, and the settings popup modal.
final class LobbyScene: SKScene {
    private let startButton = SKNode()
    private let settingsButton = SKNode()
    private let settingsPopup = SettingsPopup()

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.55, green: 0.75, blue: 0.95, alpha: 1)
        scaleMode = .resizeFill

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "SNOWBOARD RUSH"
        title.fontSize = 32
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: size.height * 0.16)
        addChild(title)

        let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        bestLabel.text = "BEST \(Int(GameState.bestDistanceMeters)) m"
        bestLabel.fontSize = 18
        bestLabel.fontColor = SKColor(white: 1, alpha: 0.9)
        bestLabel.position = CGPoint(x: 0, y: size.height * 0.16 - 40)
        addChild(bestLabel)

        setUpStartButton()
        setUpSettingsButton()

        settingsPopup.zPosition = 500
        addChild(settingsPopup)
        settingsPopup.layout(sceneSize: size)
    }

    private func setUpStartButton() {
        let background = SKShapeNode(rectOf: CGSize(width: 220, height: 64), cornerRadius: 32)
        background.fillColor = .systemYellow
        background.strokeColor = .white
        background.lineWidth = 3
        startButton.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = "게임 시작"
        label.fontSize = 24
        label.fontColor = .black
        label.verticalAlignmentMode = .center
        startButton.addChild(label)

        startButton.position = CGPoint(x: 0, y: -size.height * 0.32)
        addChild(startButton)
    }

    private func setUpSettingsButton() {
        let background = SKShapeNode(rectOf: CGSize(width: 72, height: 40), cornerRadius: 20)
        background.fillColor = SKColor(white: 0, alpha: 0.35)
        background.strokeColor = .white
        background.lineWidth = 2
        settingsButton.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "설정"
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        settingsButton.addChild(label)

        settingsButton.position = CGPoint(x: size.width / 2 - 56, y: size.height / 2 - 60)
        addChild(settingsButton)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        if !settingsPopup.isHidden {
            settingsPopup.touchBegan(at: touch.location(in: settingsPopup))
            return
        }

        let point = touch.location(in: self)
        if startButton.contains(point) {
            goToGame()
        } else if settingsButton.contains(point) {
            settingsPopup.isHidden = false
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !settingsPopup.isHidden else { return }
        settingsPopup.touchMoved(at: touch.location(in: settingsPopup))
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        settingsPopup.touchEnded()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        settingsPopup.touchEnded()
    }

    private func goToGame() {
        guard let view = view else { return }
        let game = GameScene()
        game.size = size
        game.scaleMode = scaleMode
        view.presentScene(game, transition: SKTransition.doorway(withDuration: 0.5))
    }
}
