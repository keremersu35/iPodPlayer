import SwiftUI
import Equatable

enum ViewState: Equatable {
    case loading
    case content
    case empty(message: String)
    case error(message: String)
}

@Equatable
struct StateView: View {
    let state: ViewState
    
    var body: some View {
        switch state {
        case .loading:
            LoadingView()
        case .empty(let message):
            VStack(spacing: 16) {
                Image(systemName: ImageNames.System.musicNoteList)
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text(message)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 16) {
                Image(systemName: ImageNames.System.xCircle)
                    .font(.system(size: 40))
                    .foregroundColor(.red.opacity(0.6))
                Text(message)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .minimumScaleFactor(0.4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .content:
            EmptyView()
        }
    }
}
