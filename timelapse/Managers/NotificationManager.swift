import Foundation
import UserNotifications
import SwiftUI

enum NotificationFrequency: String, CaseIterable, Identifiable, Codable {
    case never = "Never"
    case daily = "Daily"
    case weekly = "Weekly"
    case biweekly = "Bi-weekly"
    case monthly = "Monthly"
    case custom = "Custom"
    
    var id: String { self.rawValue }
    
    var description: String {
        switch self {
        case .never: return "No notifications"
        case .daily: return "Once a day"
        case .weekly: return "Once a week"
        case .biweekly: return "Every two weeks"
        case .monthly: return "Once a month"
        case .custom: return "Custom schedule"
        }
    }
    
    var daysInterval: Int {
        switch self {
        case .never: return 0
        case .daily: return 1
        case .weekly: return 7
        case .biweekly: return 14
        case .monthly: return 30
        case .custom: return 0 // Custom is handled separately
        }
    }
}

enum MilestoneType: String, CaseIterable, Identifiable, Codable {
    case percentage = "Percentage"
    case daysLeft = "Days Left"
    case specificDate = "Specific Date"
    
    var id: String { self.rawValue }
}

struct NotificationSettings: Codable, Equatable {
    var isEnabled: Bool = false
    var frequency: NotificationFrequency = .weekly
    var customDays: Int = 3 // For custom frequency
    var notifyTime: Date = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
    
    // Milestone specific settings
    var milestoneNotificationsEnabled: Bool = false
    var milestoneType: MilestoneType = .percentage
    var percentageMilestones: [Int] = [25, 50, 75, 90] // Percentage milestones (25%, 50%, 75%, 90%)
    var daysLeftMilestones: [Int] = [100, 30, 14, 7, 3, 1] // Days left milestones
    var specificDateMilestones: [Date] = [] // Specific dates for milestones
}

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    // Request notification permissions
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
            
            if let error = error {
                print("Error requesting notification authorization: \(error.localizedDescription)")
            }
        }
    }
    
    // Check if notifications are authorized
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    // Schedule notifications for an event based on its notification settings
    func scheduleNotifications(for event: Event, with settings: NotificationSettings) {
        // Remove any existing notifications for this event
        removeNotifications(for: event.id)
        
        // If notifications are disabled, just return
        if !settings.isEnabled {
            return
        }
        
        // Get the progress details
        let (daysLeft, totalDays) = event.progressDetails()
        
        // Schedule regular notifications based on frequency
        scheduleRegularNotifications(for: event, with: settings, daysLeft: daysLeft)
        
        // Schedule milestone notifications if enabled
        if settings.milestoneNotificationsEnabled {
            scheduleMilestoneNotifications(for: event, with: settings, daysLeft: daysLeft, totalDays: totalDays)
        }
    }
    
    // Schedule regular interval notifications
    private func scheduleRegularNotifications(for event: Event, with settings: NotificationSettings, daysLeft: Int) {
        // If frequency is never, don't schedule any notifications
        if settings.frequency == .never {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Determine the interval in days
        let intervalDays = settings.frequency == .custom ? settings.customDays : settings.frequency.daysInterval
        
        // If interval is 0 or negative, don't schedule
        if intervalDays <= 0 {
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = "You have \(daysLeft) days left until this event."
        content.sound = .default
        
        // Extract hour and minute from the preferred notification time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: settings.notifyTime)
        
        // Schedule notifications for the next 30 occurrences or until the event date
        for i in 0..<min(30, daysLeft / intervalDays + 1) {
            // Calculate the notification date
            guard let notificationDate = calendar.date(byAdding: .day, value: i * intervalDays, to: now) else {
                continue
            }
            
            // If this date is after the event date, break
            if notificationDate >= event.targetDate {
                break
            }
            
            // Create date components for the trigger
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: notificationDate)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute
            
            // Create the trigger and request
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let identifier = "\(event.id.uuidString)-regular-\(i)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            // Schedule the notification
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // Schedule milestone notifications
    private func scheduleMilestoneNotifications(for event: Event, with settings: NotificationSettings, daysLeft: Int, totalDays: Int) {
        let calendar = Calendar.current
        let now = Date()
        
        // Extract hour and minute from the preferred notification time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: settings.notifyTime)
        
        // Handle different milestone types
        switch settings.milestoneType {
        case .percentage:
            // Schedule percentage-based milestones
            for percentage in settings.percentageMilestones {
                // Calculate the day when this percentage will be reached
                let daysToReachPercentage = totalDays - (totalDays * percentage / 100)
                
                // If this milestone is in the future
                if daysToReachPercentage < daysLeft {
                    // Calculate the date for this milestone
                    let daysToAdd = daysLeft - daysToReachPercentage
                    guard let milestoneDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                        continue
                    }
                    
                    // Create date components for the trigger
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: milestoneDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    // Create notification content
                    let content = UNMutableNotificationContent()
                    content.title = "Milestone: \(event.title)"
                    content.body = "You've reached \(percentage)% completion for this event!"
                    content.sound = .default
                    
                    // Create the trigger and request
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let identifier = "\(event.id.uuidString)-milestone-percent-\(percentage)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    // Schedule the notification
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling milestone notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
        case .daysLeft:
            // Schedule days-left milestones
            for days in settings.daysLeftMilestones {
                // If this milestone is in the future and before the event
                if days < daysLeft {
                    // Calculate the date for this milestone
                    let daysToAdd = daysLeft - days
                    guard let milestoneDate = calendar.date(byAdding: .day, value: daysToAdd, to: now) else {
                        continue
                    }
                    
                    // Create date components for the trigger
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: milestoneDate)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    // Create notification content
                    let content = UNMutableNotificationContent()
                    content.title = "Milestone: \(event.title)"
                    content.body = "Only \(days) days left until this event!"
                    content.sound = .default
                    
                    // Create the trigger and request
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let identifier = "\(event.id.uuidString)-milestone-days-\(days)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    // Schedule the notification
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling milestone notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
            
        case .specificDate:
            // Schedule specific date milestones
            for date in settings.specificDateMilestones {
                // If this date is in the future and before the event
                if date > now && date < event.targetDate {
                    // Create date components for the trigger
                    var dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                    dateComponents.hour = timeComponents.hour
                    dateComponents.minute = timeComponents.minute
                    
                    // Create notification content
                    let content = UNMutableNotificationContent()
                    content.title = "Milestone: \(event.title)"
                    content.body = "Today is a milestone day for your event!"
                    content.sound = .default
                    
                    // Create the trigger and request
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let identifier = "\(event.id.uuidString)-milestone-date-\(dateComponents.year ?? 0)-\(dateComponents.month ?? 0)-\(dateComponents.day ?? 0)"
                    let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                    
                    // Schedule the notification
                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            print("Error scheduling milestone notification: \(error.localizedDescription)")
                        }
                    }
                }
            }
        }
    }
    
    // Special function for year tracker milestones
    func scheduleYearTrackerMilestones(for yearEvent: Event, with settings: NotificationSettings) {
        // Remove any existing notifications for this event
        removeNotifications(for: yearEvent.id)
        
        // If milestone notifications are disabled, just return
        if !settings.milestoneNotificationsEnabled {
            return
        }
        
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        
        // Extract hour and minute from the preferred notification time
        let timeComponents = calendar.dateComponents([.hour, .minute], from: settings.notifyTime)
        
        // Define special year milestones
        let specialMilestones = [
            (name: "Halfway through the year", month: 7, day: 2),
            (name: "100 days left in the year", month: 9, day: 22),
            (name: "Last quarter of the year", month: 10, day: 1),
            (name: "30 days left in the year", month: 12, day: 1),
            (name: "Last week of the year", month: 12, day: 24)
        ]
        
        // Schedule each special milestone
        for milestone in specialMilestones {
            // Create the milestone date
            guard let milestoneDate = calendar.date(from: DateComponents(year: currentYear, month: milestone.month, day: milestone.day)) else {
                continue
            }
            
            // If this date is in the future
            if milestoneDate > now {
                // Create date components for the trigger
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: milestoneDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "Year Milestone"
                content.body = milestone.name
                content.sound = .default
                
                // Create the trigger and request
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let identifier = "\(yearEvent.id.uuidString)-year-milestone-\(milestone.month)-\(milestone.day)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                // Schedule the notification
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("Error scheduling year milestone notification: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Also schedule custom day-based milestones if they're set
        if settings.milestoneType == .daysLeft && !settings.daysLeftMilestones.isEmpty {
            let (daysLeft, totalDays) = yearEvent.progressDetails()
            scheduleMilestoneNotifications(for: yearEvent, with: settings, daysLeft: daysLeft, totalDays: totalDays)
        }
    }
    
    // Remove all notifications for an event
    func removeNotifications(for eventId: UUID) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { requests in
            let identifiersToRemove = requests.filter { $0.identifier.starts(with: eventId.uuidString) }.map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        }
    }
    
    // Remove all notifications
    func removeAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
} 