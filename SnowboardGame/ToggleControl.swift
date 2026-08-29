import SpriteKit

/// A small on/off switch widget (rounded track + sliding knob), styled like a standard
/// iOS toggle. Like `SliderControl`, touch handling is done by the owning scene.
final class ToggleControl: SKNode {
    private(set) var isOn: Bool

    private let width: CGFloat = 52
    private let height: CGFloat = 28
    private let track = SKShapeNode()
    private let knob = SKShapeNode(circleOfRadius: 12)

    init(isOn: Bool) {
        self.isOn = isOn
        super.init()

        track.strokeColor = .clear
        track.path = CGPath(
            roundedRect: CGRect(x: -width / 2, y: -height / 2, width: width, height: height),
            cornerWidth: height / 2,
            cornerHeight: height / 2,
            transform: nil
        )
        addChild(track)

        knob.fillColor = .white
        knob.strokeColor = SKColor(white: 0, alpha: 0.2)
        knob.lineWidth = 1
        knob.zPosition = 1
        addChild(knob)

        refreshVisual()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var hitBox: CGRect {
        CGRect(x: -width / 2 - 10, y: -height / 2 - 10, width: width + 20, height: height + 20)
    }

    func toggle() {
        isOn.toggle()
        refreshVisual()
    }

    private func refreshVisual() {
        track.fillColor = isOn ? .systemGreen : SKColor(white: 1, alpha: 0.25)
        let knobX = isOn ? (width / 2 - height / 2) : (-width / 2 + height / 2)
        knob.position = CGPoint(x: knobX, y: 0)
    }
}
