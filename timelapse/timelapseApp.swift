//
//  timelapseApp.swift
//  timelapse
//
//  Created by Wan Menzy on 2/19/25.
//

import SwiftUI
import StoreKit
import UserNotifications

@main
struct timelapseApp: App {
    @StateObject private var eventStore = EventStore()
    @StateObject private var globalSettings = GlobalSettings()
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var paymentManager = PaymentManager.shared
    
    // Create a separate instance for initialization to avoid accessing StateObject
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init() {
        // Set the global accent color that adapts to color scheme
        UIView.appearance().tintColor = UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ?
                UIColor(Color(hex: "CCCCCC")) : // Light gray for dark mode
                UIColor(Color(hex: "333333"))  // Dark gray for light mode
        }
        
        // Set the notification delegate
        notificationCenter.delegate = NotificationDelegate.shared
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
                    
                    // Setup notifications after the view is loaded
                    setupNotifications()
                }
        }
    }
    
    private func setupNotifications() {
        // Request notification permissions if not already determined
        NotificationManager.shared.checkAuthorizationStatus { status in
            if status == .notDetermined && self.globalSettings.notificationsEnabled {
                NotificationManager.shared.requestAuthorization { granted in
                    if granted {
                        self.scheduleNotifications()
                    }
                }
            } else if status == .authorized {
                // Schedule notifications if already authorized
                self.scheduleNotifications()
            }
        }
    }
    
    private func scheduleNotifications() {
        // Schedule notifications for all events with enabled notifications
        for event in eventStore.events {
            let settings = eventStore.getNotificationSettings(for: event.id)
            if settings.isEnabled {
                // Check if this is the year tracker
                let isYearTracker = event.title == String(Calendar.current.component(.year, from: Date()))
                
                if isYearTracker && settings.milestoneNotificationsEnabled {
                    // Schedule special year tracker milestones
                    NotificationManager.shared.scheduleYearTrackerMilestones(for: event, with: settings)
                }
                
                // Schedule regular notifications
                NotificationManager.shared.scheduleNotifications(for: event, with: settings)
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

// Notification delegate to handle notifications when the app is in the foreground
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    // Handle notifications when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show the notification banner and play a sound even when the app is in the foreground
        completionHandler([.banner, .sound, .list])
    }
    
    // Handle notification interactions
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Extract the event ID from the notification identifier
        let identifier = response.notification.request.identifier
        if let eventIdString = identifier.components(separatedBy: "-").first,
           let _ = UUID(uuidString: eventIdString) {
            // Open the event in the app
            if let url = URL(string: "timelapse://event/\(eventIdString)") {
                DispatchQueue.main.async {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        completionHandler()
    }
}
