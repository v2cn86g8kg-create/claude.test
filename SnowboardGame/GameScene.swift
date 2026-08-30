import SpriteKit
import UIKit

/// Endless downhill snowboarding scene.
///
/// The world auto-scrolls to the right (mapped visually to "descending the mountain").
/// The rider follows the procedurally generated slope, launches into the air off steep
/// drops (telegraphed beforehand by a warning rail), and the player can tap freely while
/// airborne to run a 3-step trick combo (grab -> spin -> backflip) judged by a timing
/// bar - land the timing to advance the combo, miss it and the combo ends (keeping
/// whatever was already scored). There are no obstacles: the run only ends when a trick
/// rotation hasn't come back around to upright by the time the rider touches down, so
/// the body lands instead of the board (see `Player.isBoardLevel`).
final class GameScene: SKScene {
    private let terrain = Terrain(phase: CGFloat.random(in: 0..<1000), chuteSeed: UInt64.random(in: 0..<UInt64.max))
    private let player = Player()
    private let hud = HUD()
    private let cam = SKCameraNode()
    private let background = BackgroundLayers()
    private let tilt = TiltInput()
    private let groundNode = SKShapeNode()

    private var railNodes: [Int: SKNode] = [:]
    private var forwardSpeed: CGFloat = GameScene.baseForwardSpeed
    private var isRunning = true
    private var lastUpdateTime: TimeInterval?
    private var runTrickScore = 0

    /// Speed floor/ceiling for the difficulty ramp - also drives how far left the rider
    /// sits on screen (see `cameraLeadX`).
    private static let baseForwardSpeed: CGFloat = 260
    private static let maxForwardSpeed: CGFloat = 460

    /// Keeps the rider left-of-center at low speed so there's room to see what's coming,
    /// then eases that lead back toward zero as the rider picks up speed - like a real
    /// snowboarder's focus point drifting toward center as they accelerate. By the time
    /// forward speed caps out, the rider sits dead-center on screen.
    private var cameraLeadX: CGFloat {
        let range = Self.maxForwardSpeed - Self.baseForwardSpeed
        let progress = range > 0 ? (forwardSpeed - Self.baseForwardSpeed) / range : 1
        let eased = progress * progress * (3 - 2 * progress) // smoothstep
        let maxLead = size.width * 0.20
        return maxLead * (1 - max(0, min(1, eased)))
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.72, green: 0.85, blue: 0.98, alpha: 1)
        scaleMode = .resizeFill

        camera = cam
        addChild(cam)
        hud.attach(to: cam, sceneSize: size)
        hud.setBest(meters: GameState.bestDistanceMeters)

        background.zPosition = -100
        background.build(seed: CGFloat.random(in: 0..<1000))
        addChild(background)
        tilt.start()

        groundNode.fillColor = SKColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1)
        groundNode.strokeColor = SKColor(white: 1, alpha: 0.9)
        groundNode.lineWidth = 3
        groundNode.zPosition = 1
        addChild(groundNode)

        addChild(player)
        startRun()
    }

    override func willMove(from view: SKView) {
        tilt.stop()
    }

    private func startRun() {
        isRunning = true
        forwardSpeed = Self.baseForwardSpeed
        lastUpdateTime = nil
        runTrickScore = 0

        player.reset(atX: 0, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)
        cam.position = CGPoint(x: player.worldX + cameraLeadX, y: player.worldY + size.height * 0.18)
        background.update(cameraPosition: cam.position, tiltX: tilt.tiltX)

        hud.hideGameOver()
        hud.resetForNewRun()

        for (_, node) in railNodes { node.removeFromParent() }
        railNodes.removeAll()

        updateGround()
        updateRails()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }

        guard isRunning else {
            switch hud.hitTestGameOver(touch.location(in: hud)) {
            case .restart: startRun()
            case .continueRun: attemptContinue()
            case nil: break
            }
            return
        }
        guard player.isAirborne, let (trick, judgement) = hud.resolveComboTap() else { return }

        let points = Int((Double(trick.scoreBonus) * judgement.scoreMultiplier).rounded())
        if points > 0 {
            runTrickScore += points
            hud.setTrickScore(runTrickScore)
        }
        hud.showTrickResult(trick: trick, judgement: judgement, points: points)
        Haptics.trick(judgement)
        if judgement != .fail {
            player.playTrickAnimation(trick)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }
        let dt = min(lastUpdateTime.map { currentTime - $0 } ?? (1.0 / 60.0), 1.0 / 30.0)
        lastUpdateTime = currentTime

        let distance = terrain.metersDescended(atX: player.worldX)
        forwardSpeed = min(Self.maxForwardSpeed, Self.baseForwardSpeed + CGFloat(distance) * 0.35) // gentle difficulty ramp

        let wasAirborne = player.isAirborne
        player.update(dt: dt, forwardSpeed: forwardSpeed, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)

        if player.isAirborne && !wasAirborne {
            hud.startCombo()
        }
        if player.isAirborne {
            hud.updateCombo(dt: dt)
        } else if wasAirborne {
            hud.endCombo()
            // Player.update already decided, on landing, whether the board was level
            // enough - a bad landing flips straight to .crashed in that same instant.
            if player.isCrashed {
                Haptics.crash()
            } else {
                Haptics.landing()
            }
        }

        cam.position = CGPoint(x: player.worldX + cameraLeadX, y: player.worldY + size.height * 0.18)
        background.update(cameraPosition: cam.position, tiltX: tilt.tiltX)

        hud.setDistance(meters: distance)
        updateGround()
        updateRails()

        if player.isCrashed {
            endRun(distanceMeters: distance)
        }
    }

    private func endRun(distanceMeters: Double) {
        isRunning = false
        let isNewRecord = GameState.reportRun(distanceMeters: distanceMeters)
        hud.setBest(meters: GameState.bestDistanceMeters)
        CoinWallet.add(CoinWallet.reward(forDistanceMeters: distanceMeters))

        let continueText: String?
        if ContinueTracker.hasFreeContinueToday() {
            continueText = PurchaseStore.isAdsRemoved ? "이어하기" : "광고 보고 이어하기"
        } else {
            continueText = nil
        }
        hud.showGameOver(distanceMeters: distanceMeters, isNewRecord: isNewRecord, continueButtonText: continueText)
    }

    /// Handles a tap on the game-over "이어하기" button: watches a rewarded ad first
    /// (skipped entirely if ads are removed), then resumes the run in place. Once-per-
    /// calendar-day, tracked by `ContinueTracker`.
    private func attemptContinue() {
        guard ContinueTracker.hasFreeContinueToday() else { return }

        if PurchaseStore.isAdsRemoved {
            performContinue()
        } else {
            AdsManager.showRewardedAd(in: self) { [weak self] rewarded in
                guard let self, rewarded else { return }
                self.performContinue()
            }
        }
    }

    private func performContinue() {
        ContinueTracker.consumeFreeContinue()
        isRunning = true
        lastUpdateTime = nil

        player.reset(atX: player.worldX, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)
        cam.position = CGPoint(x: player.worldX + cameraLeadX, y: player.worldY + size.height * 0.18)
        background.update(cameraPosition: cam.position, tiltX: tilt.tiltX)

        hud.hideGameOver()
        updateGround()
        updateRails()
    }

    // MARK: Ground rendering

    private func updateGround() {
        let left = cam.position.x - size.width / 2 - 40
        let right = cam.position.x + size.width / 2 + 40
        let step: CGFloat = 16

        var points: [CGPoint] = []
        var x = left
        while x <= right {
            points.append(CGPoint(x: x, y: terrain.height(atX: x)))
            x += step
        }
        guard let firstPoint = points.first, let lastPoint = points.last else { return }

        let path = CGMutablePath()
        path.move(to: CGPoint(x: firstPoint.x, y: firstPoint.y + 800))
        for point in points {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y - 800))
        path.addLine(to: CGPoint(x: firstPoint.x, y: firstPoint.y - 800))
        path.closeSubpath()
        groundNode.path = path
    }

    // MARK: Rail spawning (telegraphs an upcoming steep chute)

    private func updateRails() {
        let margin: CGFloat = 80
        let left = cam.position.x - size.width / 2 - margin
        let right = cam.position.x + size.width / 2 + margin
        let visible = terrain.chutes(inRange: left...right)
        let visibleSlots = Set(visible.map { $0.slotIndex })

        for slot in Array(railNodes.keys) where !visibleSlots.contains(slot) {
            railNodes[slot]?.removeFromParent()
            railNodes.removeValue(forKey: slot)
        }

        for chute in visible where railNodes[chute.slotIndex] == nil {
            let node = makeRailNode(for: chute)
            addChild(node)
            railNodes[chute.slotIndex] = node
        }
    }

    private func makeRailNode(for chute: Chute) -> SKNode {
        let path = CGMutablePath()
        let step: CGFloat = 10
        var x = chute.railStart
        var first = true
        while x <= chute.dropStart {
            let y = terrain.height(atX: x) + 16 // float just above the snow surface
            if first {
                path.move(to: CGPoint(x: x, y: y))
                first = false
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
            x += step
        }

        let rail = SKShapeNode(path: path)
        rail.strokeColor = SKColor(red: 0.98, green: 0.82, blue: 0.15, alpha: 1)
        rail.lineWidth = 5
        rail.lineCap = .round
        rail.glowWidth = 4
        rail.zPosition = 4

        let wrapper = SKNode()
        wrapper.name = "rail"
        wrapper.addChild(rail)
        return wrapper
    }
}
