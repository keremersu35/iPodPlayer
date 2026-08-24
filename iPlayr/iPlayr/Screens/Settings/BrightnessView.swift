import SwiftUI
import UIKit

struct BrightnessView: View {
    @Environment(iPlayrButtonController.self) private var iPlayrController
    @Environment(\.navigate) private var navigate
    @State private var scope = FocusScope(id: "brightness")
    @State private var level: Double = UIScreen.main.brightness

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: String(localized: "Brightness"))
            Spacer()
            BarTrack(progress: level)
                .padding(.horizontal, 24)
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
    }

    private func setup() {
        scope.onScroll = { delta in
            let target = min(max(level + Double(delta) * 0.0625, 0), 1)
            guard target != level else { return false }
            level = target
            UIScreen.main.brightness = target
            return true
        }
        scope.onAction = { action in
            if action == .menu { navigate(.pop) }
        }
        iPlayrController.activate(scope)
    }
}
