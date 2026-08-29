import SpriteKit

/// Modal settings popup: master/effect/SFX volume sliders and a vibration toggle,
/// persisted via `SettingsStore`. It's a plain `SKNode` (not a scene), so `LobbyScene`
/// forwards touches into it via `touchBegan/touchMoved/touchEnded` while it's visible.
final class SettingsPopup: SKNode {
    private let dim = SKShapeNode()
    private let panel = SKShapeNode()
    private let closeButton = SKShapeNode(circleOfRadius: 16)

    private var masterSlider: SliderControl!
    private var effectSlider: SliderControl!
    private var sfxSlider: SliderControl!
    private var vibrationToggle: ToggleControl!

    private var activeSlider: SliderControl?
    private let panelSize = CGSize(width: 300, height: 320)

    override init() {
        super.init()
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layout(sceneSize: CGSize) {
        removeAllChildren()

        dim.path = CGPath(
            rect: CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2, width: sceneSize.width, height: sceneSize.height),
            transform: nil
        )
        dim.fillColor = SKColor(white: 0, alpha: 0.6)
        dim.strokeColor = .clear
        addChild(dim)

        panel.path = CGPath(
            roundedRect: CGRect(x: -panelSize.width / 2, y: -panelSize.height / 2, width: panelSize.width, height: panelSize.height),
            cornerWidth: 20, cornerHeight: 20, transform: nil
        )
        panel.fillColor = SKColor(red: 0.12, green: 0.14, blue: 0.20, alpha: 0.97)
        panel.strokeColor = SKColor(white: 1, alpha: 0.25)
        panel.lineWidth = 2
        addChild(panel)

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "설정"
        title.fontSize = 22
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: panelSize.height / 2 - 44)
        addChild(title)

        let rows: [(title: String, value: Float, key: String)] = [
            ("마스터 사운드", SettingsStore.masterVolume, "master"),
            ("이펙트 사운드", SettingsStore.effectVolume, "effect"),
            ("SFX 사운드", SettingsStore.sfxVolume, "sfx")
        ]

        var y: CGFloat = panelSize.height / 2 - 104
        var sliders: [SliderControl] = []
        for row in rows {
            addRowLabel(row.title, at: y)
            let slider = SliderControl(key: row.key, value: row.value, trackWidth: 128)
            slider.position = CGPoint(x: panelSize.width / 2 - 24 - 64, y: y)
            addChild(slider)
            sliders.append(slider)
            y -= 56
        }
        masterSlider = sliders[0]
        effectSlider = sliders[1]
        sfxSlider = sliders[2]

        addRowLabel("진동", at: y)
        vibrationToggle = ToggleControl(isOn: SettingsStore.vibrationEnabled)
        vibrationToggle.position = CGPoint(x: panelSize.width / 2 - 24 - 26, y: y)
        addChild(vibrationToggle)

        closeButton.fillColor = SKColor(white: 1, alpha: 0.15)
        closeButton.strokeColor = SKColor(white: 1, alpha: 0.5)
        closeButton.lineWidth = 1.5
        closeButton.position = CGPoint(x: panelSize.width / 2 - 26, y: panelSize.height / 2 - 26)
        addChild(closeButton)

        let closeLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        closeLabel.text = "\u{2715}" // ×
        closeLabel.fontSize = 16
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.horizontalAlignmentMode = .center
        closeButton.addChild(closeLabel)
    }

    private func addRowLabel(_ text: String, at y: CGFloat) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = text
        label.fontSize = 15
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: -panelSize.width / 2 + 24, y: y)
        addChild(label)
    }

    // MARK: Touch routing

    /// `point` must already be in this node's local coordinate space
    /// (e.g. `touch.location(in: settingsPopup)`).
    func touchBegan(at point: CGPoint) {
        if closeButton.contains(point) {
            isHidden = true
            return
        }
        for slider in [masterSlider!, effectSlider!, sfxSlider!] {
            let local = convert(point, to: slider)
            if slider.hitBox.contains(local) {
                activeSlider = slider
                applySliderChange(slider, atLocalX: local.x)
                return
            }
        }
        let toggleLocal = convert(point, to: vibrationToggle)
        if vibrationToggle.hitBox.contains(toggleLocal) {
            vibrationToggle.toggle()
            SettingsStore.vibrationEnabled = vibrationToggle.isOn
            return
        }
        if !panel.contains(point) {
            isHidden = true
        }
    }

    func touchMoved(at point: CGPoint) {
        guard let slider = activeSlider else { return }
        let local = convert(point, to: slider)
        applySliderChange(slider, atLocalX: local.x)
    }

    func touchEnded() {
        activeSlider = nil
    }

    private func applySliderChange(_ slider: SliderControl, atLocalX x: CGFloat) {
        let value = slider.setValue(fromLocalX: x)
        switch slider.key {
        case "master": SettingsStore.masterVolume = value
        case "effect": SettingsStore.effectVolume = value
        case "sfx": SettingsStore.sfxVolume = value
        default: break
        }
    }
}
