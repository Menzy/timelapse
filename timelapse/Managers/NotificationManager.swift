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
        
        // Special handling for year tracker
        if event.title == String(Calendar.current.component(.year, from: Date())) {
            content.title = "Year Progress"
            
            // Create a message focused on year progress
            let message: String
            if daysLeft > 180 {
                message = "\(daysLeft) days remain in \(event.title). Let's make the most of this year!"
            } else if daysLeft > 90 {
                message = "We're in the second half of \(event.title)! \(daysLeft) days to make it count."
            } else if daysLeft > 30 {
                message = "The final quarter of \(event.title) is underway. \(daysLeft) days to achieve your goals!"
            } else if daysLeft > 7 {
                message = "\(daysLeft) days left in \(event.title). Finish the year strong!"
            } else if daysLeft > 1 {
                message = "Only \(daysLeft) days remain in \(event.title). Time to reflect and prepare for \(Int(event.title)! + 1)!"
            } else if daysLeft == 1 {
                message = "Last day of \(event.title)! Tomorrow we welcome \(Int(event.title)! + 1)."
            } else {
                message = "Happy New Year! Welcome to \(Int(event.title)! + 1)!"
            }
            content.body = message
        } else {
            content.title = "Time Update: \(event.title)"
            
            // Regular event messages (unchanged)
            let message: String
            if daysLeft > 365 {
                let years = daysLeft / 365
                let remainingDays = daysLeft % 365
                message = "\(years) year\(years > 1 ? "s" : "") and \(remainingDays) day\(remainingDays != 1 ? "s" : "") until \(event.title)! The countdown continues..."
            } else if daysLeft > 30 {
                let months = daysLeft / 30
                let remainingDays = daysLeft % 30
                message = "\(months) month\(months > 1 ? "s" : "") and \(remainingDays) day\(remainingDays != 1 ? "s" : "") until \(event.title). Keep going!"
            } else if daysLeft > 7 {
                message = "Just \(daysLeft) days until \(event.title)! Getting closer every day."
            } else if daysLeft > 1 {
                message = "Almost there! Only \(daysLeft) days until \(event.title). The excitement builds!"
            } else if daysLeft == 1 {
                message = "Tomorrow is the big day - \(event.title)! Get ready!"
            } else {
                message = "Today's the day for \(event.title)! The moment has arrived!"
            }
            content.body = message
        }
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
                    
                    // Special handling for year tracker milestones
                    if event.title == String(Calendar.current.component(.year, from: Date())) {
                        content.title = "Year Milestone"
                        
                        // Create year-specific milestone messages
                        let message: String
                        switch percentage {
                        case 75:
                            message = "We're 75% through \(event.title)! The final quarter of the year begins."
                        case 50:
                            message = "Halfway through \(event.title)! What will you accomplish in the remaining months?"
                        case 25:
                            message = "First quarter of \(event.title) complete! How's your year shaping up?"
                        case 90:
                            message = "90% of \(event.title) complete! Time to start thinking about next year's goals."
                        default:
                            message = "\(percentage)% of \(event.title) has passed. Making memories every day!"
                        }
                        content.body = message
                    } else {
                        content.title = "Milestone Alert: \(event.title)"
                        
                        // Regular milestone messages (unchanged)
                        let message: String
                        switch percentage {
                        case 75:
                            message = "Wow! You're 75% of the way to \(event.title)! The final quarter begins."
                        case 50:
                            message = "Halfway there! 50% of the journey to \(event.title) complete. Keep that momentum going!"
                        case 25:
                            message = "You've completed 25% of the wait for \(event.title). The adventure continues!"
                        case 90:
                            message = "90% complete! The countdown to \(event.title) is in its final stages!"
                        default:
                            message = "You've reached \(percentage)% on your journey to \(event.title)!"
                        }
                        content.body = message
                    }
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
                    content.title = "Milestone Alert: \(event.title)"
                    
                    // Create more engaging milestone messages
                    let message: String
                    switch days {
                    case 100:
                        message = "100 days until \(event.title)! Triple digits turning to double soon!"
                    case 30:
                        message = "One month left until \(event.title)! Time to start getting excited!"
                    case 14:
                        message = "Two weeks to go until \(event.title)! The countdown is getting real!"
                    case 7:
                        message = "Just one week remains until \(event.title)! Can you feel the anticipation?"
                    case 3:
                        message = "Only 3 days left until \(event.title)! The moment is almost here!"
                    case 1:
                        message = "Tomorrow is \(event.title)! The wait is nearly over!"
                    default:
                        message = "\(days) days remain until \(event.title)! Each day brings you closer!"
                    }
                    
                    content.body = message
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
                    content.title = "Milestone Alert: \(event.title)"
                    content.body = "Today marks a special milestone on your journey to \(event.title)! Keep going!"
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
        // Check if user is subscribed
        if !PaymentManager.isUserSubscribed() {
            return
        }
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
