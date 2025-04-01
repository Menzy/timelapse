import SwiftUI

struct NavigationContentView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    let selectedTab: Int
    let eventCount: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Page control dots
            if !globalSettings.isGridLayoutAvailable || !globalSettings.showGridLayout {
                HStack(spacing: 6) {
                    ForEach(0..<eventCount, id: \.self) { index in
                        let distance = abs(selectedTab - index)
                        let size: CGFloat = distance == 0 ? 6 : max(4, 6 - CGFloat(distance))
                        let opacity: Double = distance == 0 ? 1 : max(0.3, 1 - Double(distance) * 0.2)
                        
                        Circle()
                            .fill(selectedTab == index ? 
                                 (globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white) :
                                 (globalSettings.effectiveBackgroundStyle == .light ? Color.black.opacity(opacity) : Color.white.opacity(opacity)))
                            .frame(width: size, height: size)
                    }
                }
                .animation(.easeInOut, value: selectedTab)
                .padding(.bottom, 8)
            }
            
            // Navigation bar
            NavigationBar()
        }
        .padding(.bottom, 40) // Added bottom padding to move navigation up
    }
} 