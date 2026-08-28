import SpriteKit
import UIKit

/// Endless downhill snowboarding scene.
///
/// The world auto-scrolls to the right (mapped visually to "descending the mountain").
/// The rider follows the procedurally generated slope, launches into the air off steep
/// drops, and the player can tap anywhere on screen while airborne to pull a grab/spin
/// trick - the trick tier depends on how much air has been gained. Riding (or landing)
/// into an obstacle without enough clearance ends the run.
final class GameScene: SKScene {
    private let terrain = Terrain(phase: CGFloat.random(in: 0..<1000), obstacleSeed: UInt64.random(in: 0..<UInt64.max))
    private let player = Player()
    private let hud = HUD()
    private let cam = SKCameraNode()
    private let groundNode = SKShapeNode()

    private var obstacleNodes: [Int: SKNode] = [:]
    private var forwardSpeed: CGFloat = 260
    private var isRunning = true
    private var lastUpdateTime: TimeInterval?

    /// Keeps the rider left-of-center so there's room to see what's coming.
    private let cameraLead: CGFloat = -80

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

        player.reset(atX: 0, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)
        cam.position = CGPoint(x: player.worldX + cameraLead, y: player.worldY + size.height * 0.18)

        hud.hideGameOver()

        for (_, node) in obstacleNodes { node.removeFromParent() }
        obstacleNodes.removeAll()

        updateGround()
        updateObstacles()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isRunning else {
            startRun()
            return
        }
        if player.isAirborne, let trick = player.attemptTrick() {
            hud.showTrick(trick)
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard isRunning else { return }
        let dt = min(lastUpdateTime.map { currentTime - $0 } ?? (1.0 / 60.0), 1.0 / 30.0)
        lastUpdateTime = currentTime

        let distance = terrain.metersDescended(atX: player.worldX)
        forwardSpeed = min(460, 260 + CGFloat(distance) * 0.35) // gentle difficulty ramp

        player.update(dt: dt, forwardSpeed: forwardSpeed, terrain: terrain)
        player.position = CGPoint(x: player.worldX, y: player.worldY)

        checkObstacleCollision()

        cam.position = CGPoint(x: player.worldX + cameraLead, y: player.worldY + size.height * 0.18)

        hud.setDistance(meters: distance)
        updateGround()
        updateObstacles()

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
}
