import SwiftUI

class NavigationStateManager: ObservableObject {
    @Published var showingCustomize = false
    @Published var showingTrackEvent = false
    @Published var showingSettings = false
    
    static let shared = NavigationStateManager()
    private init() {} // Singleton pattern
}