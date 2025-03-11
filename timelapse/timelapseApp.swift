//
//  timelapseApp.swift
//  timelapse
//
//  Created by Wan Menzy on 2/19/25.
//

import SwiftUI

@main
struct timelapseApp: App {
    @StateObject private var eventStore = EventStore()
    @StateObject private var globalSettings = GlobalSettings()
    @StateObject private var navigationState = NavigationStateManager.shared
    
    init() {
        // Set the global accent color
        UIView.appearance().tintColor = UIColor(Color(hex: "333333"))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalSettings)
                .onOpenURL { url in
                    handleDeepLink(url)
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
