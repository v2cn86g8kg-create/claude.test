import SpriteKit
import UIKit

/// Endless downhill snowboarding scene.
///
/// The world auto-scrolls to the right (mapped visually to "descending the mountain").
/// The rider follows the procedurally generated slope, launches into the air off steep
/// drops (telegraphed beforehand by a warning rail), and the player can tap freely while
/// airborne to run a 3-step trick combo (grab -> spin -> backflip) judged by a timing
/// bar - land the timing to advance the combo, miss it and the combo ends (keeping
/// whatever was already scored). Riding (or landing) into an obstacle without enough
/// clearance ends the run.
final class GameScene: SKScene {
    private let terrain = Terrain(phase: CGFloat.random(in: 0..<1000), obstacleSeed: UInt64.random(in: 0..<UInt64.max))
    private let player = Player()
    private let hud = HUD()
    private let cam = SKCameraNode()
    private let groundNode = SKShapeNode()

    private var obstacleNodes: [Int: SKNode] = [:]
    private var railNodes: [Int: SKNode] = [:]
    private var forwardSpeed: CGFloat = 260
    private var isRunning = true
    private var lastUpdateTime: TimeInterval?
    private var runTrickScore = 0

    /// Keeps the rider left-of-center so there's room to see what's coming - a positive
    /// value moves the camera's focal point *ahead* of the player in world space, which
    /// pushes the player's on-screen position to the left of center.
    private var cameraLeadX: CGFloat { size.width * 0.20 }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.72, green: 0.85, blue: 0.98, alpha: 1)
        scaleMode = .resizeFill

        camera = cam
        addChild(cam)
        hud.attach(to: cam, sceneSize: size)
        hud.setBest(meters: GameState.bestDistanceMeters)

        groundNode.fillColor = SKColor(red: 0.97, green: 0.98, blue: 1.0, alpha: 1)
        groundNode.strokeColor = SKColor(white: 1, alpha: 0.9)
        groundNode.lineWidth = 3
        groundNode.zPosition = 1
        addChild(groundNode)

        addChild(player)
        startRun()
    }

    private func startRun() {
        isRunning = true
        forwardSpeed = 260
        lastUpdateTime = nil
        runTrickScore = 0

        player.reset(atX: 0, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)
        cam.position = CGPoint(x: player.worldX + cameraLeadX, y: player.worldY + size.height * 0.18)

        hud.hideGameOver()
        hud.resetForNewRun()

        for (_, node) in obstacleNodes { node.removeFromParent() }
        obstacleNodes.removeAll()
        for (_, node) in railNodes { node.removeFromParent() }
        railNodes.removeAll()

        updateGround()
        updateObstacles()
        updateRails()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else {
            startRun()
            return
        }
        guard player.isAirborne, let (trick, judgement) = hud.resolveComboTap() else { return }

        let points = Int((Double(trick.scoreBonus) * judgement.scoreMultiplier).rounded())
        if points > 0 {
            runTrickScore += points
            hud.setTrickScore(runTrickScore)
        }
        hud.showTrickResult(trick: trick, judgement: judgement, points: points)
        if judgement != .fail {
            player.playTrickAnimation(trick)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }
        let dt = min(lastUpdateTime.map { currentTime - $0 } ?? (1.0 / 60.0), 1.0 / 30.0)
        lastUpdateTime = currentTime

        let distance = terrain.metersDescended(atX: player.worldX)
        forwardSpeed = min(460, 260 + CGFloat(distance) * 0.35) // gentle difficulty ramp

        let wasAirborne = player.isAirborne
        player.update(dt: dt, forwardSpeed: forwardSpeed, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)

        // Resolve collisions before touching the combo bar so a mid-air crash this frame
        // (isAirborne flips to false here) is seen by the airborne/wasAirborne check
        // below rather than being missed for a frame, which would leave the bar stuck.
        checkObstacleCollision()

        if player.isAirborne && !wasAirborne {
            hud.startCombo()
        }
        if player.isAirborne {
            hud.updateCombo(dt: dt)
        } else if wasAirborne {
            hud.endCombo()
        }

        cam.position = CGPoint(x: player.worldX + cameraLeadX, y: player.worldY + size.height * 0.18)

        hud.setDistance(meters: distance)
        updateGround()
        updateObstacles()
        updateRails()

        if player.isCrashed {
            endRun(distanceMeters: distance)
        }
    }

    // MARK: Collision

    private func checkObstacleCollision() {
        guard !player.isCrashed else { return }
        let range = (player.worldX - 40)...(player.worldX + 40)
        for obstacle in terrain.obstacles(inRange: range) {
            guard player.worldX >= obstacle.minX, player.worldX <= obstacle.maxX else { continue }
            // Clearance above the slope right now (0 while riding on the ground).
            let gap = player.position.y - terrain.height(atX: player.worldX)
            if gap < obstacle.height {
                player.crash()
                return
            }
        }
    }

    private func endRun(distanceMeters: Double) {
        isRunning = false
        let isNewRecord = GameState.reportRun(distanceMeters: distanceMeters)
        hud.setBest(meters: GameState.bestDistanceMeters)
        hud.showGameOver(distanceMeters: distanceMeters, isNewRecord: isNewRecord)
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

    // MARK: Obstacle spawning

    private func updateObstacles() {
        let margin: CGFloat = 80
        let left = cam.position.x - size.width / 2 - margin
        let right = cam.position.x + size.width / 2 + margin
        let visible = terrain.obstacles(inRange: left...right)
        let visibleSlots = Set(visible.map { $0.slotIndex })

        for slot in Array(obstacleNodes.keys) where !visibleSlots.contains(slot) {
            obstacleNodes[slot]?.removeFromParent()
            obstacleNodes.removeValue(forKey: slot)
        }

        for obstacle in visible where obstacleNodes[obstacle.slotIndex] == nil {
            let node = obstacle.makeNode()
            node.position = CGPoint(x: obstacle.worldX, y: terrain.height(atX: obstacle.worldX))
            addChild(node)
            obstacleNodes[obstacle.slotIndex] = node
        }
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
