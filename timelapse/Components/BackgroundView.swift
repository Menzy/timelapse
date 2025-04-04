import SwiftUI

struct BackgroundView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.colorScheme) private var colorScheme
    
    // Animation properties
    let isAnimating: Bool
    let previousStyle: BackgroundStyle?
    let progress: CGFloat
    
    var body: some View {
        ZStack {
            // Current background
            Group {
                switch globalSettings.effectiveBackgroundStyle {
                case .light:
                    Color.white
                case .dark:
                    Color(hex: "111111")
                case .device: 
                    colorScheme == .dark ? Color(hex: "111111") : Color.white
                case .navy:
                    globalSettings.effectiveBackgroundStyle.backgroundColor
                case .fire:
                    if let gradientColors = globalSettings.effectiveBackgroundStyle.getGradientColors() {
                        LinearGradient(
                            stops: [
                                .init(color: gradientColors.start, location: 0),
                                .init(color: gradientColors.end, location: 0.6),
                                .init(color: gradientColors.end, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        // Fallback to default if gradient isn't available
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: BackgroundStyle.defaultFireStartHex), location: 0),
                                .init(color: Color(hex: BackgroundStyle.defaultFireEndHex), location: 0.6),
                                .init(color: Color(hex: BackgroundStyle.defaultFireEndHex), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                case .dream:
                    if let gradientColors = globalSettings.effectiveBackgroundStyle.getGradientColors() {
                        LinearGradient(
                            stops: [
                                .init(color: gradientColors.start, location: 0),
                                .init(color: gradientColors.end, location: 0.6),
                                .init(color: gradientColors.end, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    } else {
                        // Fallback to default if gradient isn't available
                        LinearGradient(
                            stops: [
                                .init(color: Color(hex: BackgroundStyle.defaultDreamStartHex), location: 0),
                                .init(color: Color(hex: BackgroundStyle.defaultDreamEndHex), location: 0.6),
                                .init(color: Color(hex: BackgroundStyle.defaultDreamEndHex), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                }
            }
            
            // Animated blob transition
            if isAnimating, let previousStyle = previousStyle {
                GeometryReader { geometry in
                    ZStack {
                        // Previous background as base layer
                        Group {
                            switch previousStyle {
                            case .light:
                                Color.white
                            case .dark:
                                Color(hex: "111111")
                            case .device: 
                                colorScheme == .dark ? Color(hex: "111111") : Color.white
                            case .navy:
                                previousStyle.backgroundColor
                            case .fire:
                                if let gradientColors = previousStyle.getGradientColors() {
                                    LinearGradient(
                                        stops: [
                                            .init(color: gradientColors.start, location: 0),
                                            .init(color: gradientColors.end, location: 0.6),
                                            .init(color: gradientColors.end, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                } else {
                                    // Fallback to default
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color(hex: BackgroundStyle.defaultFireStartHex), location: 0),
                                            .init(color: Color(hex: BackgroundStyle.defaultFireEndHex), location: 0.6),
                                            .init(color: Color(hex: BackgroundStyle.defaultFireEndHex), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            case .dream:
                                if let gradientColors = previousStyle.getGradientColors() {
                                    LinearGradient(
                                        stops: [
                                            .init(color: gradientColors.start, location: 0),
                                            .init(color: gradientColors.end, location: 0.6),
                                            .init(color: gradientColors.end, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                } else {
                                    // Fallback to default
                                    LinearGradient(
                                        stops: [
                                            .init(color: Color(hex: BackgroundStyle.defaultDreamStartHex), location: 0),
                                            .init(color: Color(hex: BackgroundStyle.defaultDreamEndHex), location: 0.6),
                                            .init(color: Color(hex: BackgroundStyle.defaultDreamEndHex), location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                }
                            }
                        }
                        
                        // Animated blob mask revealing the new background
                        ThemeTransitionShape(progress: progress)
                            .frame(width: geometry.size.width * 3, height: geometry.size.height * 3)
                            .position(x: -geometry.size.width * 0.3, y: -geometry.size.height * 0.3)
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    .drawingGroup()
                }
            }
        }
        .ignoresSafeArea()
    }
} 