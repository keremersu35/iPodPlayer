import SwiftUI
import Equatable

@Equatable
struct StatusBar: View {
    @EnvironmentObject private var playerManager: AppleMusicManager
    var title: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                Text(title)
                    .foregroundColor(.black)
                    .font(.system(size: 14))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if playerManager.isPlaying || playerManager.isPaused {
                    Image(playerManager.isPlaying ? ImageNames.Custom.play : ImageNames.Custom.pause)
                        .resizable()
                        .frame(width: 12, height: 14)
                    Spacer()
                        .frame(width: 8)
                }
                BatteryIconView(level: CGFloat(UIDevice.current.batteryLevel))
                    .frame(width: 28, height: 14)
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 25)
            .background(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.statusBar1, .statusBar2, .statusBar3, .statusBar4]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: 25)
            )
            Rectangle()
                .fill(.statusBarDivider)
                .frame(maxWidth: .infinity, maxHeight: 1)
        }
    }
}

@Equatable
struct BatteryIconView: View {
    var level: CGFloat
    private let batteryFillColors: [Color] = [.batteryFill1, .batteryFill2, .batteryFill3, .batteryFill4,
                                              .batteryFill5, .batteryFill6, .batteryFill7, .batteryFill8,
                                              .batteryFill9, .batteryFill10, .batteryFill11, .batteryFill12]
    private let batteryEmpty: [Color] = [.batteryEmpty1,.batteryEmpty2,.batteryEmpty3]
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .stroke(.black.opacity(0.8), lineWidth: 0.5)
                .frame(width: 24, height: 12)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: batteryEmpty),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 24, height: 12)
            
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient:Gradient(colors:batteryFillColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: max(0, 24 * level), height: 12)
            
            Rectangle()
                .fill(
                    level == 1
                    ? LinearGradient(
                        gradient: Gradient(colors: batteryFillColors),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    : LinearGradient(
                        gradient: Gradient(colors: batteryEmpty),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: 5)
                .border(.gray, width: 0.5)
                .offset(x: 24)
        }
        .padding(2)
        .frame(width: 28, height: 14)
    }
}
