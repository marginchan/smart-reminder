import SwiftUI

struct ToastView: View {
    let message: String
    @Binding var isShowing: Bool
    var duration: TimeInterval = 2.0
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(Color.black.opacity(0.85))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                    }
                }
            }
            .accessibilityLabel(message)
    }
}
