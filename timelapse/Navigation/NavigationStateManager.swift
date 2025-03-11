import SwiftUI
class NavigationStateManager: ObservableObject {
    @Published var showingCustomize = false
    @Published var showingTrackEvent = false
    @Published var showingSettings = false
    @Published var selectedTab = 0
    
    static let shared = NavigationStateManager()
    private init() {} // Singleton pattern
}