import SwiftUI

struct SnackbarView: View {
    let message: String
    var duration: TimeInterval = 3.0
    
    @Binding var isVisible: Bool
    
    var body: some View {
        if isVisible {
            Text(message)
                .foregroundColor(.white)
                .padding()
                .background(Color.black.opacity(0.8))
                .cornerRadius(10)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                        withAnimation {
                            isVisible = false
                        }
                    }
                }
        }
    }
}

extension View {
    func snackbar(message: String, isVisible: Binding<Bool>, duration: TimeInterval = 3.0) -> some View {
        ZStack {
            self
            VStack {
                Spacer()
                SnackbarView(message: message, duration: duration, isVisible: isVisible)
            }
            .padding(.bottom, 24)
        }
    }
}
