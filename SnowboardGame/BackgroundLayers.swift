import SpriteKit

/// A single parallax "plane" in the diorama-style backdrop, drawn once as a handful of
/// repeating silhouette tiles and then just repositioned every frame - never
/// regenerated. This is the classic multiplane-camera trick from old hand-drawn
/// animation (Disney's multiplane camera stacked painted glass panes at different
/// distances from the camera so nearer ones panned faster) - and the same idea behind
/// the layered dioramas in games like Dragon Quest's overworld.
///
/// `parallaxFactor` controls how much of the camera's horizontal movement shows through:
/// near 0 barely moves (very far away), 1 moves exactly with the world (same as the
/// actual playable terrain, right up front). Vertically the layer just tracks the
/// camera directly, so the skyline stays in the same screen band forever instead of
/// drifting off during a long, endlessly-descending run.
final class ParallaxLayer: SKNode {
    private let parallaxFactor: CGFloat
    private let repeatWidth: CGFloat

    init(parallaxFactor: CGFloat, repeatWidth: CGFloat, tiles: [SKNode]) {
        self.parallaxFactor = parallaxFactor
        self.repeatWidth = repeatWidth
        super.init()
        for (index, tile) in tiles.enumerated() {
            tile.position.x = CGFloat(index - 1) * repeatWidth // lay 3 copies side by side
            addChild(tile)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(cameraPosition: CGPoint) {
        let trackedX = cameraPosition.x * (1 - parallaxFactor)
        position = CGPoint(x: trackedX.truncatingRemainder(dividingBy: repeatWidth), y: cameraPosition.y)
    }
}

/// Builds and owns the full diorama backdrop: three mountain/hill silhouette planes at
/// increasing parallax speed and decreasing distance (hazy far peaks -> mid slopes ->
/// darker near foothills), sitting behind the actual playable slope.
final class BackgroundLayers: SKNode {
    private var layers: [ParallaxLayer] = []

    private struct LayerSpec {
        let parallax: CGFloat
        let repeatWidth: CGFloat
        let baseline: CGFloat   // screen-space height above center where the ridge sits
        let peak: CGFloat       // how tall the jagged silhouette is
        let freq: CGFloat       // how rugged/frequent the peaks are
        let color: SKColor
        let seedOffset: CGFloat
    }

    private static let specs: [LayerSpec] = [
        LayerSpec(parallax: 0.06, repeatWidth: 1500, baseline: 210, peak: 190, freq: 0.55,
                  color: SKColor(red: 0.66, green: 0.75, blue: 0.88, alpha: 0.90), seedOffset: 0.0),
        LayerSpec(parallax: 0.16, repeatWidth: 1050, baseline: 130, peak: 140, freq: 0.85,
                  color: SKColor(red: 0.50, green: 0.63, blue: 0.78, alpha: 0.95), seedOffset: 3.1),
        LayerSpec(parallax: 0.34, repeatWidth: 720, baseline: 70, peak: 95, freq: 1.30,
                  color: SKColor(red: 0.28, green: 0.45, blue: 0.52, alpha: 1.00), seedOffset: 6.7)
    ]

    func build(seed: CGFloat) {
        removeAllChildren()
        layers.removeAll()

        for (index, spec) in Self.specs.enumerated() {
            let tiles = (0..<3).map { _ in
                makeTile(spec: spec, seed: seed + spec.seedOffset)
            }
            let layer = ParallaxLayer(parallaxFactor: spec.parallax, repeatWidth: spec.repeatWidth, tiles: tiles)
            layer.zPosition = -10 + CGFloat(index) // far -> near, all well behind the ground (zPosition 1)
            addChild(layer)
            layers.append(layer)
        }
    }

    /// Called every frame with the camera's current position.
    func update(cameraPosition: CGPoint) {
        for layer in layers {
            layer.update(cameraPosition: cameraPosition)
        }
    }

    private func makeTile(spec: LayerSpec, seed: CGFloat) -> SKNode {
        let shape = SKShapeNode(path: Self.silhouettePath(spec: spec, seed: seed))
        shape.fillColor = spec.color
        shape.strokeColor = .clear
        return shape
    }

    private static func silhouettePath(spec: LayerSpec, seed: CGFloat) -> CGPath {
        let step: CGFloat = 24
        var points: [CGPoint] = []
        var x: CGFloat = 0
        while x <= spec.repeatWidth {
            let y = spec.baseline
                + spec.peak * 0.6 * sin(x * 0.006 * spec.freq + seed)
                + spec.peak * 0.4 * sin(x * 0.017 * spec.freq + seed * 1.7)
            points.append(CGPoint(x: x, y: y))
            x += step
        }

        let path = CGMutablePath()
        guard let first = points.first, let last = points.last else { return path }
        // Extend the fill far below so there's never a gap under the ridge line,
        // regardless of screen height.
        path.move(to: CGPoint(x: first.x, y: -1200))
        for point in points {
            path.addLine(to: point)
        }
        path.addLine(to: CGPoint(x: last.x, y: -1200))
        path.closeSubpath()
        return path
    }
}
