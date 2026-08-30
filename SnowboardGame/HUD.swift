import SpriteKit

/// Fixed UI layer, parented to the scene's camera so it always stays put on screen no
/// matter where the world has scrolled to: best record (top-left), distance
/// (top-center), trick score (top-right), the trick-combo timing bar (bottom), and the
/// game-over panel.
final class HUD: SKNode {
    private let distanceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let trickScoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let trickResultLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")

    private let gameOverLayer = SKNode()
    private let finalDistanceLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let newRecordLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let continueButton = SKNode()
    private let continueLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let restartButton = SKNode()

    enum GameOverAction {
        case restart
        case continueRun
    }

    // MARK: Trick combo bar

    private let comboLayer = SKNode()
    private let comboTrickNameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let comboGoodZone = SKShapeNode()
    private let comboGreatZone = SKShapeNode()
    private let comboPerfectTick = SKShapeNode()
    private let comboMarker = SKShapeNode(circleOfRadius: 9)

    private var sceneSize: CGSize = .zero
    private var comboActive = false
    private var comboStep = 0
    private var comboTime: TimeInterval = 0

    private let comboBarHalfWidth: CGFloat = 120
    /// Seconds for the marker to sweep once from the left edge to the right edge before
    /// snapping back to the left and sweeping again - later steps sweep faster.
    private static let stepSweepDuration: [TimeInterval] = [1.0, 0.75, 0.55]
    private static let stepGoodFrac: [CGFloat] = [0.46, 0.36, 0.28]      // fraction of half-width
    private static let stepGreatFrac: [CGFloat] = [0.24, 0.19, 0.15]
    private static let stepPerfectFrac: [CGFloat] = [0.10, 0.08, 0.06]

    func attach(to camera: SKCameraNode, sceneSize: CGSize) {
        self.sceneSize = sceneSize
        camera.addChild(self)
        zPosition = 100

        let topY = sceneSize.height / 2 - 60

        bestLabel.fontSize = 16
        bestLabel.fontColor = SKColor(white: 1, alpha: 0.85)
        bestLabel.horizontalAlignmentMode = .left
        bestLabel.position = CGPoint(x: -sceneSize.width / 2 + 20, y: topY + 4)
        bestLabel.text = "BEST 0 m"
        addChild(bestLabel)

        distanceLabel.fontSize = 30
        distanceLabel.fontColor = .white
        distanceLabel.horizontalAlignmentMode = .center
        distanceLabel.position = CGPoint(x: 0, y: topY)
        distanceLabel.text = "0 m"
        addChild(distanceLabel)

        trickScoreLabel.fontSize = 22
        trickScoreLabel.fontColor = .systemYellow
        trickScoreLabel.horizontalAlignmentMode = .right
        trickScoreLabel.position = CGPoint(x: sceneSize.width / 2 - 20, y: topY)
        trickScoreLabel.text = "0"
        addChild(trickScoreLabel)

        trickResultLabel.fontSize = 24
        trickResultLabel.fontColor = .white
        trickResultLabel.alpha = 0
        trickResultLabel.position = CGPoint(x: 0, y: 40)
        addChild(trickResultLabel)

        setUpComboLayer()
        setUpGameOverLayer(sceneSize: sceneSize)
    }

    private func setUpComboLayer() {
        comboLayer.alpha = 0
        comboLayer.zPosition = 90
        let barY = -sceneSize.height / 2 + 90
        comboLayer.position = CGPoint(x: 0, y: barY)
        addChild(comboLayer)

        let background = SKShapeNode(rectOf: CGSize(width: comboBarHalfWidth * 2 + 16, height: 16), cornerRadius: 8)
        background.fillColor = SKColor(white: 0, alpha: 0.4)
        background.strokeColor = SKColor(white: 1, alpha: 0.5)
        background.lineWidth = 1.5
        comboLayer.addChild(background)

        comboGoodZone.fillColor = SKColor.systemYellow.withAlphaComponent(0.35)
        comboGoodZone.strokeColor = .clear
        comboLayer.addChild(comboGoodZone)

        comboGreatZone.fillColor = SKColor.systemGreen.withAlphaComponent(0.55)
        comboGreatZone.strokeColor = .clear
        comboLayer.addChild(comboGreatZone)

        comboPerfectTick.fillColor = .white
        comboPerfectTick.strokeColor = .clear
        comboLayer.addChild(comboPerfectTick)

        comboMarker.fillColor = .systemRed
        comboMarker.strokeColor = .white
        comboMarker.lineWidth = 2
        comboMarker.zPosition = 1
        comboLayer.addChild(comboMarker)

        comboTrickNameLabel.fontSize = 18
        comboTrickNameLabel.fontColor = .white
        comboTrickNameLabel.position = CGPoint(x: 0, y: 22)
        comboLayer.addChild(comboTrickNameLabel)
    }

    private func layoutComboZones(forStep step: Int) {
        let goodWidth = comboBarHalfWidth * 2 * Self.stepGoodFrac[step]
        let greatWidth = comboBarHalfWidth * 2 * Self.stepGreatFrac[step]
        let perfectWidth = comboBarHalfWidth * 2 * Self.stepPerfectFrac[step]
        comboGoodZone.path = CGPath(rect: CGRect(x: -goodWidth / 2, y: -6, width: goodWidth, height: 12), transform: nil)
        comboGreatZone.path = CGPath(rect: CGRect(x: -greatWidth / 2, y: -6, width: greatWidth, height: 12), transform: nil)
        comboPerfectTick.path = CGPath(rect: CGRect(x: -perfectWidth / 2, y: -7, width: max(perfectWidth, 2), height: 14), transform: nil)
    }

    /// Called when the player launches into the air - shows the bar and starts step 0.
    func startCombo() {
        comboActive = true
        comboStep = 0
        comboTime = 0
        comboLayer.removeAllActions()
        comboLayer.alpha = 1
        comboMarker.position = CGPoint(x: -comboBarHalfWidth, y: 0) // starts at the left edge
        layoutComboZones(forStep: 0)
        comboTrickNameLabel.text = AirTrick.allCases[0].shortName
    }

    /// The marker's current position as a fraction of the bar (-1 = left edge, 0 =
    /// center, +1 = right edge): a one-way sweep left-to-right that snaps back to the
    /// left edge and starts over each time it reaches the end, like a radar sweep.
    private func markerFraction(forStep step: Int, time: TimeInterval) -> CGFloat {
        let duration = Self.stepSweepDuration[step]
        let progress = (time / duration).truncatingRemainder(dividingBy: 1.0)
        return CGFloat(progress) * 2 - 1
    }

    /// Called every frame while the combo is active to animate the moving marker.
    func updateCombo(dt: TimeInterval) {
        guard comboActive else { return }
        comboTime += dt
        comboMarker.position.x = markerFraction(forStep: comboStep, time: comboTime) * comboBarHalfWidth
    }

    /// Called on a tap while the combo is active. Judges the current step from where the
    /// marker is right now, advances to the next step on anything but a miss, and ends
    /// the combo on a miss or after the final step. Returns the trick/judgement so the
    /// caller can score it and play the matching animation.
    func resolveComboTap() -> (trick: AirTrick, judgement: TrickJudgement)? {
        guard comboActive else { return nil }

        let offsetFrac = abs(markerFraction(forStep: comboStep, time: comboTime))
        let judgement: TrickJudgement
        if offsetFrac <= Self.stepPerfectFrac[comboStep] {
            judgement = .perfect
        } else if offsetFrac <= Self.stepGreatFrac[comboStep] {
            judgement = .great
        } else if offsetFrac <= Self.stepGoodFrac[comboStep] {
            judgement = .good
        } else {
            judgement = .fail
        }

        let trick = AirTrick.allCases[comboStep]

        if !judgement.continuesCombo {
            endCombo()
        } else {
            comboStep += 1
            if comboStep >= AirTrick.allCases.count {
                endCombo()
            } else {
                comboTime = 0
                layoutComboZones(forStep: comboStep)
                comboTrickNameLabel.text = AirTrick.allCases[comboStep].shortName
            }
        }
        return (trick, judgement)
    }

    /// Hides the combo bar - called on a miss, on finishing all steps, or when the
    /// player lands/crashes with the combo still in progress.
    func endCombo() {
        guard comboActive || comboLayer.alpha > 0 else { return }
        comboActive = false
        comboLayer.removeAllActions()
        comboLayer.run(SKAction.sequence([SKAction.wait(forDuration: 0.15), SKAction.fadeOut(withDuration: 0.2)]))
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

        setUpContinueButton()
        setUpRestartButton()
    }

    private func setUpContinueButton() {
        let background = SKShapeNode(rectOf: CGSize(width: 260, height: 52), cornerRadius: 26)
        background.fillColor = .systemGreen
        background.strokeColor = .white
        background.lineWidth = 2
        continueButton.addChild(background)

        continueLabel.fontSize = 18
        continueLabel.fontColor = .white
        continueLabel.verticalAlignmentMode = .center
        continueButton.addChild(continueLabel)

        continueButton.position = CGPoint(x: 0, y: -55)
        gameOverLayer.addChild(continueButton)
    }

    private func setUpRestartButton() {
        let background = SKShapeNode(rectOf: CGSize(width: 200, height: 44), cornerRadius: 22)
        background.fillColor = SKColor(white: 1, alpha: 0.15)
        background.strokeColor = SKColor(white: 1, alpha: 0.6)
        background.lineWidth = 1.5
        restartButton.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "다시 시작"
        label.fontSize = 16
        label.fontColor = SKColor(white: 1, alpha: 0.9)
        label.verticalAlignmentMode = .center
        restartButton.addChild(label)

        restartButton.position = CGPoint(x: 0, y: -120)
        gameOverLayer.addChild(restartButton)
    }

    func setDistance(meters: Double) {
        distanceLabel.text = "\(Int(meters)) m"
    }

    func setBest(meters: Double) {
        bestLabel.text = "BEST \(Int(meters)) m"
    }

    func setTrickScore(_ score: Int) {
        trickScoreLabel.text = "\(score)"
    }

    func showTrickResult(trick: AirTrick, judgement: TrickJudgement, points: Int) {
        trickResultLabel.removeAllActions()
        if judgement == .fail {
            trickResultLabel.text = "\(trick.shortName) MISS"
            trickResultLabel.fontColor = .systemRed
        } else {
            trickResultLabel.text = "\(trick.shortName) \(judgement.label) +\(points)"
            trickResultLabel.fontColor = judgementColor(judgement)
        }
        trickResultLabel.alpha = 1
        trickResultLabel.setScale(0.8)
        trickResultLabel.position = CGPoint(x: 0, y: 40)

        let scaleUp = SKAction.scale(to: 1.1, duration: 0.15)
        let up = SKAction.moveBy(x: 0, y: 30, duration: 0.7)
        let fadeAfterHold = SKAction.sequence([SKAction.wait(forDuration: 0.2), SKAction.fadeOut(withDuration: 0.5)])
        trickResultLabel.run(SKAction.sequence([scaleUp, SKAction.group([up, fadeAfterHold])]))
    }

    private func judgementColor(_ judgement: TrickJudgement) -> SKColor {
        switch judgement {
        case .perfect: return .systemYellow
        case .great: return .systemGreen
        case .good: return .white
        case .fail: return .systemRed
        }
    }

    func resetForNewRun() {
        setTrickScore(0)
        comboLayer.removeAllActions()
        comboActive = false
        comboLayer.alpha = 0
    }

    /// `continueButtonText` is non-nil when a continue is offered (either "광고 보고
    /// 이어하기" or, with ads removed, just "이어하기") - nil hides that button entirely,
    /// leaving only restart.
    func showGameOver(distanceMeters: Double, isNewRecord: Bool, continueButtonText: String?) {
        finalDistanceLabel.text = "\(Int(distanceMeters)) m"
        newRecordLabel.text = isNewRecord ? "NEW RECORD!" : ""

        if let text = continueButtonText {
            continueButton.isHidden = false
            continueLabel.text = text
            restartButton.position = CGPoint(x: 0, y: -120)
        } else {
            continueButton.isHidden = true
            restartButton.position = CGPoint(x: 0, y: -55)
        }

        gameOverLayer.alpha = 0
        gameOverLayer.run(SKAction.fadeIn(withDuration: 0.3))
    }

    func hideGameOver() {
        gameOverLayer.removeAllActions()
        gameOverLayer.alpha = 0
    }

    /// `point` must be in this node's local coordinate space (e.g. `touch.location(in:
    /// hud)`). Returns nil when the game-over panel isn't showing or the tap missed
    /// both buttons.
    func hitTestGameOver(_ point: CGPoint) -> GameOverAction? {
        guard gameOverLayer.alpha > 0.5 else { return nil }
        if !restartButton.isHidden, restartButton.contains(convert(point, to: restartButton)) {
            return .restart
        }
        if !continueButton.isHidden, continueButton.contains(convert(point, to: continueButton)) {
            return .continueRun
        }
        return nil
    }
}
