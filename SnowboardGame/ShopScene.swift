import SpriteKit
import UIKit

/// The shop: coin-purchased cosmetic skins for the board/rider, plus the real-money
/// "remove ads" purchase. Reachable from the lobby, returns there via the back button.
final class ShopScene: SKScene {
    private let backButton = SKNode()
    private let coinLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private let removeAdsButton = SKNode()
    private let removeAdsLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
    private var itemRows: [(item: CosmeticItem, node: SKNode)] = []

    override func didMove(to view: SKView) {
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.10, green: 0.13, blue: 0.20, alpha: 1)
        scaleMode = .resizeFill

        let title = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        title.text = "상점"
        title.fontSize = 28
        title.fontColor = .white
        title.position = CGPoint(x: 0, y: size.height * 0.40)
        addChild(title)

        coinLabel.fontSize = 17
        coinLabel.fontColor = .systemYellow
        coinLabel.horizontalAlignmentMode = .right
        coinLabel.position = CGPoint(x: size.width / 2 - 24, y: size.height * 0.40)
        addChild(coinLabel)

        setUpBackButton()
        setUpItemRows()
        setUpRemoveAdsButton()
        refresh()
    }

    override func willMove(from view: SKView) {
        removeAllActions()
    }

    // MARK: Layout

    private func setUpBackButton() {
        let background = SKShapeNode(rectOf: CGSize(width: 72, height: 40), cornerRadius: 20)
        background.fillColor = SKColor(white: 1, alpha: 0.12)
        background.strokeColor = .white
        background.lineWidth = 2
        backButton.addChild(background)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "뒤로"
        label.fontSize = 16
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        backButton.addChild(label)

        backButton.position = CGPoint(x: -size.width / 2 + 56, y: size.height * 0.40)
        addChild(backButton)
    }

    private func setUpItemRows() {
        let rowHeight: CGFloat = 62
        var y = size.height * 0.26
        for item in CosmeticsStore.items {
            let row = makeItemRow(item: item)
            row.position = CGPoint(x: 0, y: y)
            addChild(row)
            itemRows.append((item, row))
            y -= rowHeight
        }
    }

    private func makeItemRow(item: CosmeticItem) -> SKNode {
        let container = SKNode()
        let width = min(340, size.width - 40)

        let background = SKShapeNode(rectOf: CGSize(width: width, height: 52), cornerRadius: 14)
        background.fillColor = SKColor(white: 1, alpha: 0.08)
        background.strokeColor = SKColor(white: 1, alpha: 0.2)
        background.lineWidth = 1
        background.name = "hitArea"
        container.addChild(background)

        let swatch = SKShapeNode(circleOfRadius: 15)
        swatch.fillColor = item.bodyColor
        swatch.strokeColor = item.boardColor
        swatch.lineWidth = 4
        swatch.position = CGPoint(x: -width / 2 + 32, y: 0)
        container.addChild(swatch)

        let nameLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        nameLabel.text = item.name
        nameLabel.fontSize = 16
        nameLabel.fontColor = .white
        nameLabel.horizontalAlignmentMode = .left
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: -width / 2 + 58, y: 0)
        container.addChild(nameLabel)

        let statusLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        statusLabel.name = "status"
        statusLabel.fontSize = 15
        statusLabel.horizontalAlignmentMode = .right
        statusLabel.verticalAlignmentMode = .center
        statusLabel.position = CGPoint(x: width / 2 - 20, y: 0)
        container.addChild(statusLabel)

        return container
    }

    private func setUpRemoveAdsButton() {
        let width = min(340, size.width - 40)
        let background = SKShapeNode(rectOf: CGSize(width: width, height: 56), cornerRadius: 16)
        background.fillColor = SKColor.systemPurple.withAlphaComponent(0.35)
        background.strokeColor = .white
        background.lineWidth = 2
        removeAdsButton.addChild(background)

        removeAdsLabel.fontSize = 16
        removeAdsLabel.fontColor = .white
        removeAdsLabel.verticalAlignmentMode = .center
        removeAdsButton.addChild(removeAdsLabel)

        removeAdsButton.position = CGPoint(x: 0, y: -size.height * 0.36)
        addChild(removeAdsButton)
    }

    private func refresh() {
        coinLabel.text = "COIN \(CoinWallet.balance)"

        for (item, row) in itemRows {
            guard let status = row.childNode(withName: "status") as? SKLabelNode else { continue }
            if item.id == CosmeticsStore.equippedID {
                status.text = "장착중"
                status.fontColor = .systemGreen
            } else if CosmeticsStore.isOwned(item) {
                status.text = "장착"
                status.fontColor = .white
            } else {
                status.text = "\(item.price) 코인"
                status.fontColor = .systemYellow
            }
        }

        if PurchaseStore.isAdsRemoved {
            removeAdsLabel.text = "광고 제거 완료"
            removeAdsButton.alpha = 0.6
        } else {
            removeAdsLabel.text = "광고 제거 \(PurchaseStore.removeAdsDisplayPrice)"
            removeAdsButton.alpha = 1.0
        }
    }

    // MARK: Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)

        if backButton.contains(point) {
            goToLobby()
            return
        }

        if !PurchaseStore.isAdsRemoved, removeAdsButton.contains(point) {
            PurchaseStore.purchaseRemoveAds { [weak self] _ in
                self?.refresh()
            }
            return
        }

        for (item, row) in itemRows where row.contains(point) {
            if CosmeticsStore.isOwned(item) {
                CosmeticsStore.equip(item)
            } else {
                CosmeticsStore.purchase(item)
            }
            refresh()
            return
        }
    }

    private func goToLobby() {
        guard let view = view else { return }
        let lobby = LobbyScene()
        lobby.size = size
        lobby.scaleMode = scaleMode
        view.presentScene(lobby, transition: SKTransition.fade(withDuration: 0.3))
    }
}
