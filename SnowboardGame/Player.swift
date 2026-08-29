import SpriteKit

enum PlayerState {
    case riding
    case airborne
    case crashed
}

/// The snowboarder. Owns its own physics/animation state; `GameScene` drives it each
/// frame via `update(dt:forwardSpeed:terrain:)`. The trick-combo judging itself lives in
/// `HUD` (it's a UI/timing concern); `playTrickAnimation` here is just the visual spin
/// GameScene triggers once a combo step has been judged.
final class Player: SKNode {
    private(set) var state: PlayerState = .riding

    /// World-space position. Kept separate from the SpriteKit `position` so the scene
    /// controls exactly when the visual node is moved (after camera-relevant math).
    private(set) var worldX: CGFloat = 0
    private(set) var worldY: CGFloat = 0

    private var velocityY: CGFloat = 0

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
        boardNode.strokeColor = .clear
        boardNode.position = CGPoint(x: 0, y: -10)

        bodyNode = SKShapeNode(circleOfRadius: 10)
        bodyNode.strokeColor = .white
        bodyNode.lineWidth = 1.5
        bodyNode.position = CGPoint(x: 0, y: 2)

        super.init()
        zPosition = 10
        addChild(boardNode)
        addChild(bodyNode)
        applyCosmetics()
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
        state = .riding
        zRotation = 0
        alpha = 1
        removeAllActions()
        applyCosmetics()
    }

    /// Recolors the board/rider to whatever is currently equipped in the Shop. Called
    /// on init and on every `reset` (covers both a fresh run and a game-over continue)
    /// so a skin bought/equipped since the app launched always shows up.
    private func applyCosmetics() {
        let item = CosmeticsStore.equippedItem
        boardNode.fillColor = item.boardColor
        bodyNode.fillColor = item.bodyColor
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
            }

        case .airborne:
            velocityY += Self.gravity * CGFloat(dt)
            worldY += velocityY * CGFloat(dt)

            let gap = worldY - groundY
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

    /// Plays the spin/grab flourish for a combo step that was just judged. Purely
    /// cosmetic - the judging itself already happened in `HUD`.
    func playTrickAnimation(_ trick: AirTrick) {
        let spin = SKAction.rotate(byAngle: trick.rotation, duration: trick.animationDuration)
        spin.timingMode = .easeInEaseOut
        run(spin)
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
