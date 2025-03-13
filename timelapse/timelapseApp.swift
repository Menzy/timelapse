//
//  timelapseApp.swift
//  timelapse
//
//  Created by Wan Menzy on 2/19/25.
//

import SwiftUI
import StoreKit

@main
struct timelapseApp: App {
    @StateObject private var eventStore = EventStore()
    @StateObject private var globalSettings = GlobalSettings()
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var paymentManager = PaymentManager.shared
    
    init() {
        // Set the global accent color that adapts to color scheme
        UIView.appearance().tintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color(hex: "CCCCCC")) : // Light gray for dark mode
                UIColor(Color(hex: "333333"))  // Dark gray for light mode
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalSettings)
                .environmentObject(eventStore)
                .environmentObject(paymentManager)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .task {
                    // Initialize payment manager
                    await paymentManager.loadProducts()
                    await paymentManager.updateSubscriptionStatus()
                }
        }
    }
    
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "timelapse" else { return }
        
        if url.host == "event" {
            // Extract event ID from URL
            if let eventIdString = url.pathComponents.dropFirst().first,
               let eventId = UUID(uuidString: eventIdString) {
                // Find the event in the store
                if let eventIndex = eventStore.findEventIndex(withId: eventId) {
                    // Switch to grid view if not already
                    globalSettings.showGridLayout = false
                    
                    // Set the selected tab to the event index
                    DispatchQueue.main.async {
                        navigationState.selectedTab = eventIndex
                    }
                }
            }
        }
    }
}
