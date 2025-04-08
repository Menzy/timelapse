import SwiftUI

struct NavigationContentView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    let selectedTab: Int
    let eventCount: Int
    
    // Calculate dot size based on device type
    private func dotSize(for index: Int) -> CGFloat {
        let distance = abs(selectedTab - index)
        let baseSizeSelected = DeviceType.isIPad ? 8.0 : 6.0
        let baseSizeUnselected = DeviceType.isIPad ? 6.0 : 4.0
        
        return distance == 0 ? 
            baseSizeSelected : 
            max(baseSizeUnselected, baseSizeSelected - CGFloat(distance))
    }
    
    var body: some View {
        VStack(spacing: DeviceType.isIPad ? 10 : 8) {
            // Page control dots
            if !globalSettings.isGridLayoutAvailable || !globalSettings.showGridLayout {
                HStack(spacing: DeviceType.isIPad ? 8 : 6) {
                    ForEach(0..<eventCount, id: \.self) { index in
                        let distance = abs(selectedTab - index)
                        let opacity: Double = distance == 0 ? 1 : max(0.3, 1 - Double(distance) * 0.2)
                        
                        Circle()
                            .fill(selectedTab == index ? 
                                 (globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white) :
                                 (globalSettings.effectiveBackgroundStyle == .light ? Color.black.opacity(opacity) : Color.white.opacity(opacity)))
                            .frame(width: dotSize(for: index), height: dotSize(for: index))
                    }
                }
                .padding(.horizontal, DeviceType.isIPad ? 8 : 6)
                .padding(.vertical, DeviceType.isIPad ? 6 : 5)
                .background(
                    Capsule()
                        .fill(
                            globalSettings.effectiveBackgroundStyle == .light
                                ? Color.black.opacity(0.15)
                                : Color.white.opacity(0.15)
                        )
                        .blur(radius: 0.2)
                )
                // Add blur effect with Material if on iOS 15+
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.5))
                )
                .clipShape(Capsule())
                .animation(.easeInOut, value: selectedTab)
                .padding(.bottom, DeviceType.isIPad ? 10 : 8)
            }
            
            // Navigation bar
            NavigationBar()
        }
        .padding(.bottom, DeviceType.isIPad ? 50 : 40) // Adjusted bottom padding for iPad
    }
} 