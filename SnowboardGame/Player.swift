import SpriteKit

enum PlayerState {
    case riding
    case airborne
    case crashed
}

/// The snowboarder. Owns its own physics/animation state; `GameScene` drives it each
/// frame via `update(dt:forwardSpeed:terrain:)` and forwards taps into `attemptTrick()`.
final class Player: SKNode {
    private(set) var state: PlayerState = .riding

    /// World-space position. Kept separate from the SpriteKit `position` so the scene
    /// controls exactly when the visual node is moved (after camera-relevant math).
    private(set) var worldX: CGFloat = 0
    private(set) var worldY: CGFloat = 0

    private var velocityY: CGFloat = 0

    /// Meters of air gained above the slope so far during the current jump.
    private(set) var peakAirMeters: Double = 0
    private var hasTrickedThisAir = false
    private(set) var lastTrick: AirTrick?

    private let bodyNode: SKShapeNode
    private let boardNode: SKShapeNode

    static let gravity: CGFloat = -1400 // px/s^2

    /// How far ahead (in world-x px) we peek to decide whether the ground is about to
    /// drop away into a jump.
    static let launchLookahead: CGFloat = 50
    /// How much *extra* the ground has to drop over that lookahead - beyond what the
    /// steady downhill grade alone would already account for - before it counts as a
    /// launch-worthy lip rather than just normal descent.
    static let launchThreshold: CGFloat = 8
    /// Extra drop (px) -> target apex height (px) above the slope.
    static let launchApexScale: CGFloat = 2.2
    /// Safety cap so an unusually steep patch of terrain can't send the rider absurdly high.
    static let launchApexCap: CGFloat = 190

    override init() {
        boardNode = SKShapeNode(rectOf: CGSize(width: 34, height: 6), cornerRadius: 3)
        boardNode.fillColor = .systemYellow
        boardNode.strokeColor = .clear
        boardNode.position = CGPoint(x: 0, y: -10)

        bodyNode = SKShapeNode(circleOfRadius: 10)
        bodyNode.fillColor = .systemRed
        bodyNode.strokeColor = .white
        bodyNode.lineWidth = 1.5
        bodyNode.position = CGPoint(x: 0, y: 2)

        super.init()
        zPosition = 10
        addChild(boardNode)
        addChild(bodyNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var isAirborne: Bool { state == .airborne }
    var isCrashed: Bool { state == .crashed }

    func reset(atX x: CGFloat, terrain: Terrain) {
        worldX = x
        worldY = terrain.height(atX: x)
        velocityY = 0
        peakAirMeters = 0
        hasTrickedThisAir = false
        lastTrick = nil
        state = .riding
        zRotation = 0
        alpha = 1
        removeAllActions()
    }

    /// Called every frame. `forwardSpeed` is the current auto-scroll speed (px/s).
    func update(dt: TimeInterval, forwardSpeed: CGFloat, terrain: Terrain) {
        guard state != .crashed else { return }

        worldX += forwardSpeed * CGFloat(dt)
        let groundY = terrain.height(atX: worldX)

        switch state {
        case .riding:
            worldY = groundY
            let slope = terrain.steepness(atX: worldX)
            zRotation = atan(-slope) * 0.4

            // Look a bit ahead: if the ground there is lower than a steady descent alone
            // would put it, there's a lip coming up - launch off it. Sizing the jump off
            // this *extra* drop (rather than the raw one) keeps the ordinary downhill
            // grade from being mistaken for a jump on its own.
            let aheadGroundY = terrain.height(atX: worldX + Self.launchLookahead)
            let extraDrop = (groundY - aheadGroundY) - Terrain.baseSlope * Self.launchLookahead
            if extraDrop > Self.launchThreshold {
                state = .airborne
                let targetApex = min(extraDrop * Self.launchApexScale, Self.launchApexCap)
                velocityY = sqrt(2 * abs(Self.gravity) * targetApex)
                peakAirMeters = 0
                hasTrickedThisAir = false
                lastTrick = nil
            }

        case .airborne:
            velocityY += Self.gravity * CGFloat(dt)
            worldY += velocityY * CGFloat(dt)

            let gap = worldY - groundY
            let gapMeters = Double(max(0, gap) / Terrain.pixelsPerMeter)
            peakAirMeters = max(peakAirMeters, gapMeters)

            if gap <= 0 && velocityY < 0 {
                worldY = groundY
                velocityY = 0
                removeAllActions()
                zRotation = 0
                state = .riding
            }

        case .crashed:
            break
        }
    }

    /// Called on a screen tap while airborne. Picks a trick tier from the current air
    /// height and plays a matching spin/grab animation. Only the first tap per jump counts.
    @discardableResult
    func attemptTrick() -> AirTrick? {
        guard state == .airborne, !hasTrickedThisAir else { return nil }
        hasTrickedThisAir = true
        let trick = AirTrick.forAirHeight(meters: peakAirMeters)
        lastTrick = trick

        let spin = SKAction.rotate(byAngle: trick.rotation, duration: trick.animationDuration)
        spin.timingMode = .easeInEaseOut
        run(spin)
        return trick
    }

    func crash() {
        state = .crashed
        velocityY = 0
        removeAllActions()
        let tip = SKAction.rotate(toAngle: .pi / 2, duration: 0.25)
        let fade = SKAction.fadeAlpha(to: 0.4, duration: 0.25)
        run(SKAction.group([tip, fade]))
    }
}
