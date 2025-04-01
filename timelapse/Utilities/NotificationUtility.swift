import SwiftUI
import Combine

// Utility for handling theme change notifications
enum NotificationUtility {
    // Set up observers for theme change notifications to force UI refresh
    static func setupThemeChangeObservers(
        for globalSettings: GlobalSettings
    ) -> [AnyCancellable] {
        let notificationNames = [
            "NavyThemeChanged",
            "FireThemeChanged", 
            "DreamThemeChanged",
            "AllThemesReset"
        ]
        
        return notificationNames.map { name in
            NotificationCenter.default.publisher(for: Notification.Name(name))
                .receive(on: RunLoop.main)
                .sink { _ in
                    // Force refresh by triggering objectWillChange
                    globalSettings.objectWillChange.send()
                }
        }
    }
    
    // Schedule the next day update at midnight
    static func scheduleNextDayUpdate(completion: @escaping () -> Void) {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + midnight.timeIntervalSince(Date())) {
            completion()
        }
    }
} 