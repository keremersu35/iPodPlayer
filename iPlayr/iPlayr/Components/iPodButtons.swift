import SwiftUI

@MainActor
final class WheelTracker {
    var lastAngle: CGFloat?
    var counter: CGFloat = 0

    func reset() {
        lastAngle = nil
        counter = 0
    }
}

struct iPlayrButtons: View {
    private static let wheelDiameterRatio: CGFloat = 0.79

    @State private var wheel = WheelTracker()
    @Environment(iPlayrButtonController.self) private var buttonController
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size.width
            let buttonOffset = size * 0.32

            ZStack {
                Circle()
                    .fill(theme.currentTheme.wheelColor)
                    .frame(width: size * Self.wheelDiameterRatio, height: size * Self.wheelDiameterRatio)
                    .gesture(dragGesture(in: size))
                    .accessibilityLabel("Scroll wheel")
                    .accessibilityAdjustableAction { direction in
                        switch direction {
                        case .increment: buttonController.scrollDown()
                        case .decrement: buttonController.scrollUp()
                        @unknown default: break
                        }
                    }

                Image(theme.currentTheme.wheelInnerAppearance)
                    .resizable()
                    .frame(width: size * 0.29, height: size * 0.29)
                    .onTapGesture { buttonController.selectButtonPressed() }
                    .accessibilityLabel("Select")
                    .accessibilityAddTraits(.isButton)

                makeTextButton("MENU", offset: -buttonOffset,
                               onTap: { buttonController.menuButtonPressed() },
                               onLongPress: { buttonController.menuLongPressed() })
                makeIconButton(imageName: ImageNames.System.playPause, accessibilityLabel: "Play or pause", offsetY: buttonOffset) { buttonController.playPauseButtonPressed() }
                makeSeekButton(imageName: ImageNames.System.forwardEndAlt, accessibilityLabel: "Next track", offsetX: buttonOffset,
                             onTap: { buttonController.forwardEndAltButtonPressed() },
                             onLongPressStart: { buttonController.forwardLongPressStarted() },
                             onLongPressEnd: { buttonController.forwardLongPressEnded() })
                makeSeekButton(imageName: ImageNames.System.backwardEndAlt, accessibilityLabel: "Previous track", offsetX: -buttonOffset,
                             onTap: { buttonController.backwardEndAltButtonPressed() },
                             onLongPressStart: { buttonController.backwardLongPressStarted() },
                             onLongPressEnd: { buttonController.backwardLongPressEnded() })
            }
            .frame(width: size, height: size * 0.9)
        }
    }
    
    private func dragGesture(in size: CGFloat) -> some Gesture {
        let center = size * Self.wheelDiameterRatio / 2
        return DragGesture(minimumDistance: 0)
            .onChanged { v in
                var angle = atan2(v.location.x - center, center - v.location.y) * 180 / .pi
                if angle < 0 { angle += 360 }

                guard let previousAngle = wheel.lastAngle else {
                    wheel.lastAngle = angle
                    return
                }

                var theta = previousAngle - angle
                if theta > 180 { theta -= 360 }
                if theta < -180 { theta += 360 }
                wheel.lastAngle = angle

                wheel.counter += theta

                if wheel.counter > 30 {
                    buttonController.scrollUp()
                } else if wheel.counter < -30 {
                    buttonController.scrollDown()
                }

                if abs(wheel.counter) > 30 { wheel.counter = 0 }
            }
            .onEnded { _ in
                wheel.reset()
            }
    }
    
    @ViewBuilder
    private func makeIconButton(imageName: String, accessibilityLabel: LocalizedStringKey, offsetX: CGFloat = 0, offsetY: CGFloat = 0, action: @escaping () -> Void) -> some View {
        iPlayrIconButton(imageName: imageName, accessibilityLabel: accessibilityLabel, onTapAction: action)
            .offset(x: offsetX, y: offsetY)
            .environment(theme)
    }

    @ViewBuilder
    private func makeSeekButton(imageName: String, accessibilityLabel: LocalizedStringKey, offsetX: CGFloat = 0, offsetY: CGFloat = 0,
                               onTap: @escaping () -> Void,
                               onLongPressStart: @escaping () -> Void,
                               onLongPressEnd: @escaping () -> Void) -> some View {
        iPlayrSeekButton(imageName: imageName,
                        accessibilityLabel: accessibilityLabel,
                        onTapAction: onTap,
                        onLongPressStart: onLongPressStart,
                        onLongPressEnd: onLongPressEnd)
            .offset(x: offsetX, y: offsetY)
            .environment(theme)
    }

    @ViewBuilder
    private func makeTextButton(_ text: LocalizedStringKey, offset: CGFloat,
                                onTap: @escaping () -> Void,
                                onLongPress: @escaping () -> Void) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(theme.currentTheme.wheelIconTint)
            .padding(20)
            .contentShape(Rectangle())
            .offset(y: offset)
            .onTapGesture(perform: onTap)
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50, perform: onLongPress)
            .accessibilityLabel(text)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Main menu", onLongPress)
    }
}

struct iPlayrIconButton: View {
    let imageName: String
    let accessibilityLabel: LocalizedStringKey
    let onTapAction: () -> Void
    @Environment(ThemeManager.self) private var theme

    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .frame(width: 24, height: 12)
            .foregroundColor(theme.currentTheme.wheelIconTint)
            .padding(20)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapAction)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}

struct iPlayrSeekButton: View {
    let imageName: String
    let accessibilityLabel: LocalizedStringKey
    let onTapAction: () -> Void
    let onLongPressStart: () -> Void
    let onLongPressEnd: () -> Void
    @Environment(ThemeManager.self) private var theme
    @State private var isPressed: Bool = false

    var body: some View {
        Image(systemName: imageName)
            .resizable()
            .frame(width: 24, height: 12)
            .foregroundColor(theme.currentTheme.wheelIconTint)
            .padding(20)
            .contentShape(Rectangle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .onTapGesture(perform: onTapAction)
            .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50,
                               pressing: { pressing in
                                   withAnimation(.easeInOut(duration: 0.1)) {
                                       isPressed = pressing
                                   }
                                   if pressing {
                                       onLongPressStart()
                                   } else {
                                       onLongPressEnd()
                                   }
                               },
                               perform: {})
            .accessibilityLabel(accessibilityLabel)
            .accessibilityAddTraits(.isButton)
    }
}
