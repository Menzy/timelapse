//
//  GlobalSettings.swift
//  timelapse
//
//  Created by Wan Menzy on 2/18/25.
//


import SwiftUI

class GlobalSettings: ObservableObject {
    @Published var backgroundStyle: BackgroundStyle = .light
    @Published var showGridLayout: Bool = false
    
    // Computed properties to check if premium features are available based on subscription status
    var isGridLayoutAvailable: Bool {
        return PaymentManager.isUserSubscribed()
    }
    
    var areNotificationsAvailable: Bool {
        return true
    }
    @Published private var systemIsDark: Bool = false
    
    // Notification-related settings
    @Published var notificationsEnabled: Bool = false
    @Published var defaultNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    @Published var defaultNotificationFrequency: NotificationFrequency = .weekly
    
    init() {
        // Load saved background style from UserDefaults
        if let savedStyle = UserDefaults.standard.string(forKey: "backgroundStyle"),
           let style = BackgroundStyle(rawValue: savedStyle) {
            backgroundStyle = style
        }
        
        // Load grid layout preference
        showGridLayout = UserDefaults.standard.bool(forKey: "showGridLayout")
        
        // Load notification preferences
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if let savedTime = UserDefaults.standard.object(forKey: "defaultNotificationTime") as? Date {
            defaultNotificationTime = savedTime
        }
        if let savedFrequency = UserDefaults.standard.string(forKey: "defaultNotificationFrequency"),
           let frequency = NotificationFrequency(rawValue: savedFrequency) {
            defaultNotificationFrequency = frequency
        }
    }
    
    var effectiveBackgroundStyle: BackgroundStyle {
        if backgroundStyle == .device {
            return systemIsDark ? .dark : .light
        }
        return backgroundStyle
    }
    
    var invertedColor: Color {
        effectiveBackgroundStyle == .light ? Color.black : Color.white
    }
    
    var invertedSecondaryColor: Color {
        effectiveBackgroundStyle == .light ? Color.gray : Color(white: 0.5)
    }
    
    func updateSystemAppearance(_ isDark: Bool) {
        systemIsDark = isDark
        objectWillChange.send()
    }
    
    // Request notification permissions
    func requestNotificationPermissions(completion: @escaping (Bool) -> Void) {
        NotificationManager.shared.requestAuthorization { granted in
            self.notificationsEnabled = granted
            self.saveSettings()
            completion(granted)
        }
    }
    
    // Check notification authorization status
    func checkNotificationAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        NotificationManager.shared.checkAuthorizationStatus(completion: completion)
    }
}

// Extension to handle persistence
extension GlobalSettings {
    func saveSettings() {
        UserDefaults.standard.set(backgroundStyle.rawValue, forKey: "backgroundStyle")
        UserDefaults.standard.set(showGridLayout, forKey: "showGridLayout")
        
        // Save notification preferences
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(defaultNotificationTime, forKey: "defaultNotificationTime")
        UserDefaults.standard.set(defaultNotificationFrequency.rawValue, forKey: "defaultNotificationFrequency")
    }
}
