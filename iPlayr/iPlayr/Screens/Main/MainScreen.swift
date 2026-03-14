import SwiftUI

struct iPlayrView: View {
    @StateObject private var iPlayrController: iPlayrButtonController = .init()
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var playerManager: AppleMusicManager

    var body: some View {
        VStack() {
            Spacer()
            iPlayrScreen()
                .environmentObject(iPlayrController)
                .padding(.horizontal)
                .environmentObject(theme)
            Spacer()
            iPlayrButtons()
                .environmentObject(iPlayrController)
                .environmentObject(theme)
            Spacer()
        }
        .background(
            Image(theme.currentTheme.caseAppearance)
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        )
        .onAppear {
            iPlayrController.setGlobalPlaybackHandler { action in
                Task {
                    switch action {
                    case .playPause: try? await playerManager.togglePlayPause()
                    case .forwardEndAlt: try? await playerManager.skipToNextTrack()
                    case .backwardEndAlt: try? await playerManager.skipToPreviousTrack()
                    default: break
                    }
                }
            }
        }
    }
}
