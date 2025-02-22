import SwiftUI

struct NavigationButton: View {
    let iconName: String
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(.white.opacity(0.9))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(hex: "121212").opacity(0.5))
                        .overlay(
                            Circle()
                                .stroke(LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 0.5)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(NavigationButtonStyle())
    }
}

struct NavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct NavigationBar: View {
    @StateObject private var navigationState = NavigationStateManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            NavigationButton(iconName: "edit") {
                navigationState.showingCustomize = true
            }
            
            NavigationButton(iconName: "track") {
                navigationState.showingTrackEvent = true
            }
            
            NavigationButton(iconName: "settings") {
                navigationState.showingSettings = true
            }
        }
        .padding(6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.95))
                .overlay(
                    Capsule()
                        .stroke(LinearGradient(
                            colors: [.white.opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        .padding(.bottom, 60)
    }
}
