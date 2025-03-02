import SwiftUI

struct NavigationButton: View {
    let iconName: String
    let action: () -> Void
    @State private var isPressed = false
    @Namespace private var animation
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 16, height: 16)
                .foregroundColor(.white.opacity(0.9))
                .padding(8)
                .background(
                    Circle()
                        .fill(Color(hex: "121212"))
                        .overlay(
                            Circle()
                                .stroke(LinearGradient(
                                    colors: [.white.opacity(0.2), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ), lineWidth: 0.5)
                        )
                )
                
        }
        .buttonStyle(NavigationButtonStyle())
    }
}

struct NavigationButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct NavigationBar: View {
    @StateObject private var navigationState = NavigationStateManager.shared
    
    var body: some View {
        HStack(spacing: 12) {
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
        .padding(8)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color(hex: "141414")],
                        startPoint: UnitPoint(x: 0.25, y: 0.93),
                        endPoint: UnitPoint(x: 0.75, y: 0.07)
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            RadialGradient(
                                colors: [Color.black, Color(hex: "131313")],
                                center: .center,
                                startRadius: 0,
                                endRadius: 8
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        .padding(.bottom, 60)
    }
}
