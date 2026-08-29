import SwiftUI
import SpriteKit

struct ContentView: View {
    private let scene: LoadingScene = {
        let scene = LoadingScene()
        scene.size = UIScreen.main.bounds.size
        scene.scaleMode = .resizeFill
        return scene
    }()

    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
    }
}
