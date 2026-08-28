import SpriteKit

/// Fixed UI layer, parented to the scene's camera so it always stays put on screen no
/// matter where the world has scrolled to: distance (top-center), personal best
/// (top-right), a trick popup, and a game-over panel.
final class HUD: SKNode {
    private let distanceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let trickLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    private let gameOverLayer = SKNode()
    private let finalDistanceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let newRecordLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")

    func attach(to camera: SKCameraNode, sceneSize: CGSize) {
        camera.addChild(self)
        zPosition = 100

        let topY = sceneSize.height / 2 - 60

        distanceLabel.fontSize = 30
        distanceLabel.fontColor = .white
        distanceLabel.horizontalAlignmentMode = .center
        distanceLabel.position = CGPoint(x: 0, y: topY)
        distanceLabel.text = "0 m"
        addChild(distanceLabel)

        bestLabel.fontSize = 16
        bestLabel.fontColor = SKColor(white: 1, alpha: 0.85)
        bestLabel.horizontalAlignmentMode = .right
        bestLabel.position = CGPoint(x: sceneSize.width / 2 - 20, y: topY + 4)
        bestLabel.text = "BEST 0 m"
        addChild(bestLabel)

        trickLabel.fontSize = 26
        trickLabel.fontColor = .systemYellow
        trickLabel.alpha = 0
        trickLabel.position = CGPoint(x: 0, y: 40)
        addChild(trickLabel)

        setUpGameOverLayer(sceneSize: sceneSize)
    }

    private func setUpGameOverLayer(sceneSize: CGSize) {
        gameOverLayer.alpha = 0
        gameOverLayer.zPosition = 200
        addChild(gameOverLayer)

        let dim = SKShapeNode(rectOf: sceneSize)
        dim.fillColor = SKColor(white: 0, alpha: 0.55)
        dim.strokeColor = .clear
        gameOverLayer.addChild(dim)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "GAME OVER"
        title.fontSize = 36
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: 50)
        gameOverLayer.addChild(title)

        finalDistanceLabel.fontSize = 22
        finalDistanceLabel.fontColor = .white
        finalDistanceLabel.position = CGPoint(x: 0, y: 5)
        gameOverLayer.addChild(finalDistanceLabel)

        newRecordLabel.fontSize = 18
        newRecordLabel.fontColor = .systemYellow
        newRecordLabel.text = ""
        newRecordLabel.position = CGPoint(x: 0, y: -25)
        gameOverLayer.addChild(newRecordLabel)

        let restart = SKLabelNode(fontNamed: "AvenirNext-Bold")
        restart.text = "TAP TO RESTART"
        restart.fontSize = 18
        restart.fontColor = SKColor(white: 1, alpha: 0.85)
        restart.position = CGPoint(x: 0, y: -70)
        gameOverLayer.addChild(restart)
    }

    func setDistance(meters: Double) {
        distanceLabel.text = "\(Int(meters)) m"
    }

    func setBest(meters: Double) {
        bestLabel.text = "BEST \(Int(meters)) m"
    }

    func showTrick(_ trick: AirTrick) {
        trickLabel.removeAllActions()
        trickLabel.text = trick.displayName
        trickLabel.alpha = 1
        trickLabel.setScale(0.8)
        trickLabel.position = CGPoint(x: 0, y: 40)

        let scaleUp = SKAction.scale(to: 1.1, duration: 0.15)
        let up = SKAction.moveBy(x: 0, y: 30, duration: 0.7)
        let fadeAfterHold = SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.5)])
        trickLabel.run(SKAction.sequence([scaleUp, SKAction.group([up, fadeAfterHold])]))
    }

    func showGameOver(distanceMeters: Double, isNewRecord: Bool) {
        finalDistanceLabel.text = "\(Int(distanceMeters)) m"
        newRecordLabel.text = isNewRecord ? "NEW RECORD!" : ""
        gameOverLayer.alpha = 0
        gameOverLayer.run(SKAction.fadeIn(withDuration: 0.3))
    }

    func hideGameOver() {
        gameOverLayer.removeAllActions()
        gameOverLayer.alpha = 0
    }
}
