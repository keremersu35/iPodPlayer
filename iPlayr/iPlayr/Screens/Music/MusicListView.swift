import SwiftUI
import Combine

struct MusicListView: View {
    @EnvironmentObject private var iPlayrController: iPlayrButtonController
    @State private var cancellables = Set<AnyCancellable>()
    @Environment(\.navigate) private var navigate
    @Environment(\.dismiss) private var dismiss
    private var menus: [Menu] = [
        .init(id: 0, name: "Cover Flow", next: true),
        .init(id: 1, name: "Playlists", next: true),
        .init(id: 2, name: "Albums", next: true),
    ]
    @State private var selectedIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusBar(title: "Music")
            ForEach(menus.indices, id: \.self) { index in
                MenuItemView(menu: menus[index], isSelected: selectedIndex == index)
            }
            Spacer()
        }
        .shadowedBackground()
        .onAppear(perform: setup)
        .onChange(of: iPlayrController.selectedIndex) { _, newValue in
            // Sadece kontrol bizdeyse güncelle
            guard iPlayrController.activePage == .music else { return }
            selectedIndex = newValue
        }
        .navigationBarBackButtonHidden()
        .onDisappear {
            iPlayrController.saveCurrentIndex()
            // View kapanınca kontrolü bırak (Eğer hala bizdeyse)
            // Ama genellikle yeni view almış olur, o yüzden zararsız
            // iPlayrController.releaseControl() 
        }
    }
    
    private func setup() {
        iPlayrController.setActivePage(.music, menuCount: menus.count)
        selectedIndex = iPlayrController.selectedIndex
        
        // EXCLUSIVE CONTROL: Tek yetkili handler ol
        iPlayrController.takeControl { action in
            handleButtonAction(action)
        }
    }
    
    // Eski sink yapısı yerine doğrudan fonksiyon çağrısı
    private func handleButtonAction(_ action: ButtonAction) {
        switch action {
        case .menu:
            dismiss()
        case .select:
            navigation()
        default: break
        }
    }
    
    private func navigation() {
        // Navigasyon başladığı an kontrolü bırak (Sağır ol)
        iPlayrController.releaseControl()
        
        // Guard'a gerek kalmadı çünkü artık input almayacağız ama güvenlik için kalsın
        guard iPlayrController.activePage == .music else { return }
        
        if selectedIndex == 0 { // CoverFlow
             iPlayrController.setRightView(false)
        }
        
        let route: Route
        switch selectedIndex {
        case 0: route = .coverFlow
        case 1: route = .playlists
        case 2: route = .albums
        default: route = .playlists
        }
        navigate(.push(route))
    }
}
