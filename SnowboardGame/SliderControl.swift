import SpriteKit

/// A small horizontal slider widget: a filled track plus a draggable handle. Value is
/// 0...1. `SKNode` has no built-in touch handling, so the owning scene is responsible
/// for hit-testing `hitBox` and calling `setValue(fromLocalX:)` as the drag continues.
final class SliderControl: SKNode {
    let key: String
    private(set) var value: Float

    private let trackWidth: CGFloat
    private let barHeight: CGFloat = 6
    private let track = SKShapeNode()
    private let fill = SKShapeNode()
    private let handle = SKShapeNode(circleOfRadius: 11)

    init(key: String, value: Float, trackWidth: CGFloat = 130) {
        self.key = key
        self.value = value
        self.trackWidth = trackWidth
        super.init()

        track.fillColor = SKColor(white: 1, alpha: 0.25)
        track.strokeColor = .clear
        addChild(track)

        fill.fillColor = .systemYellow
        fill.strokeColor = .clear
        addChild(fill)

        handle.fillColor = .white
        handle.strokeColor = SKColor(white: 0, alpha: 0.3)
        handle.lineWidth = 1
        handle.zPosition = 1
        addChild(handle)

        track.path = barPath(width: trackWidth)
        refreshVisual()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Local-space hit box, generous enough to comfortably grab the handle with a finger.
    var hitBox: CGRect {
        CGRect(x: -trackWidth / 2 - 16, y: -20, width: trackWidth + 32, height: 40)
    }

    @discardableResult
    func setValue(fromLocalX x: CGFloat) -> Float {
        let clamped = max(-trackWidth / 2, min(trackWidth / 2, x))
        value = Float((clamped + trackWidth / 2) / trackWidth)
        refreshVisual()
        return value
    }

    private func refreshVisual() {
        let filledWidth = trackWidth * CGFloat(value)
        fill.path = barPath(width: filledWidth)
        handle.position = CGPoint(x: -trackWidth / 2 + filledWidth, y: 0)
    }

    /// A rounded bar of `width`, always anchored to the track's left edge (so a partial
    /// fill grows rightward rather than staying centered).
    private func barPath(width: CGFloat) -> CGPath {
        let w = max(width, 0.001)
        return CGPath(
            roundedRect: CGRect(x: -trackWidth / 2, y: -barHeight / 2, width: w, height: barHeight),
            cornerWidth: barHeight / 2,
            cornerHeight: barHeight / 2,
            transform: nil
        )
    }
}
