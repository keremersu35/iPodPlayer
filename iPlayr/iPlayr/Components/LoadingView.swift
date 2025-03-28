import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView()
            .tint(.screenFrame)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
