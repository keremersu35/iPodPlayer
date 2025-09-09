import SwiftUI

struct iPlayrButtons: View {
    @State private var lastAngle: CGFloat = 0
    @State private var counter: CGFloat = 0
    @EnvironmentObject private var buttonController: iPlayrButtonController
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            let buttonOffset = size * 0.32
            
            ZStack {
                Circle()
                    .fill(RadialGradient(
                        gradient: Gradient(colors: [theme.currentTheme.wheelColor]),
                        center: .center,
                        startRadius: 10,
                        endRadius: size * 0.4
                    ))
                    .frame(width: size * 0.79, height: size * 0.79)
                    .gesture(dragGesture(in: size))

                Image(theme.currentTheme.wheelInnerAppearance)
                    .resizable()
                    .frame(width: size * 0.29, height: size * 0.29)
                    .onTapGesture { buttonController.selectButtonPressed() }

                makeTextButton("MENU", offset: -buttonOffset) { buttonController.menuButtonPressed() }
                makeIconButton(imageName: ImageNames.System.playPause, offsetY: buttonOffset) { buttonController.playPauseButtonPressed() }
                makeIconButton(imageName: ImageNames.System.forwardEndAlt, offsetX: buttonOffset) { buttonController.forwardEndAltButtonPressed() }
                makeIconButton(imageName: ImageNames.System.backwardEndAlt, offsetX: -buttonOffset) { buttonController.backwardEndAltButtonPressed() }
            }
            .frame(width: size, height: size * 0.9)
        }
    }
    
    private func dragGesture(in size: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { v in
                var angle = atan2(v.location.x - size * 0.4, size * 0.4 - v.location.y) * 180 / .pi
                if angle < 0 { angle += 360 }
                
                let theta = lastAngle - angle
                lastAngle = angle
                
                if abs(theta) < 30 { counter += theta }
                
                if counter > 30 && buttonController.selectedIndex > 0 {
                    buttonController.scrollUp()
                } else if counter < -30 && buttonController.selectedIndex < buttonController.menuCount - 1 {
                    buttonController.scrollDown()
                }
                
                if abs(counter) > 30 { counter = 0 }
            }
            .onEnded { _ in counter = 0 }
    }
    
    @ViewBuilder
    private func makeIconButton(imageName: String, offsetX: CGFloat = 0, offsetY: CGFloat = 0, action: @escaping () -> Void) -> some View {
        iPlayrIconButton(imageName: imageName, onTapAction: action)
            .offset(x: offsetX, y: offsetY)
            .environmentObject(theme)
    }
    
    @ViewBuilder
    private func makeTextButton(_ text: String, offset: CGFloat, action: @escaping () -> Void) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(theme.currentTheme.wheelIconTint)
            .padding(20)
            .offset(y: offset)
            .onTapGesture(perform: action)
    }
}

struct iPlayrIconButton: View {
    let imageName: String
    let onTapAction: () -> Void
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .frame(width: 24, height: 12)
            .foregroundColor(theme.currentTheme.wheelIconTint)
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapAction)
    }
}
