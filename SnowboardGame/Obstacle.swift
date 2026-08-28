import SpriteKit

enum ObstacleKind {
    case rock
    case tree

    var color: SKColor {
        switch self {
        case .rock: return SKColor(red: 0.55, green: 0.55, blue: 0.58, alpha: 1)
        case .tree: return SKColor(red: 0.16, green: 0.45, blue: 0.28, alpha: 1)
        }
    }
}

/// A single obstacle sitting on the slope. Generated deterministically (see
/// `Terrain.obstacle(inSlot:)`) so nothing needs to be stored persistently - the scene
/// just spawns/despawns the matching SKNode as it scrolls in and out of view.
struct Obstacle {
    let slotIndex: Int
    let worldX: CGFloat
    let width: CGFloat
    let height: CGFloat
    let kind: ObstacleKind

    var minX: CGFloat { worldX - width / 2 }
    var maxX: CGFloat { worldX + width / 2 }

    /// Builds the visual node. Positioned so its base sits at local y = 0 (ground level);
    /// the caller places the wrapper at (worldX, terrain height) each frame.
    func makeNode() -> SKNode {
        let shape = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: kind == .rock ? width * 0.3 : 3)
        shape.fillColor = kind.color
        shape.strokeColor = kind.color.blended(withFraction: 0.3, of: .black) ?? kind.color
        shape.lineWidth = 2
        shape.position = CGPoint(x: 0, y: height / 2)

        let wrapper = SKNode()
        wrapper.name = "obstacle"
        wrapper.zPosition = 5
        wrapper.addChild(shape)
        return wrapper
    }
}
