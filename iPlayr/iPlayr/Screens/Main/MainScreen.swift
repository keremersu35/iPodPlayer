import SwiftUI

struct iPlayrView: View {
    @StateObject private var iPlayrController: iPlayrButtonController = .init()
    @EnvironmentObject private var theme: ThemeManager
    
    var body: some View {
        VStack () {
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
    }
}
