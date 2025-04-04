import Foundation
import WidgetKit

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    private let eventsKey = "savedEvents"
    @Published var displaySettings: [UUID: DisplaySettings] = [:]
    private let displaySettingsKey = "savedDisplaySettings"
    @Published var notificationSettings: [UUID: NotificationSettings] = [:]
    private let notificationSettingsKey = "savedNotificationSettings"
    
    // The key for the year tracker event that will be shared with the widget
    static let yearTrackerKey = "yearTrackerEvent"
    // The key for all events that will be shared with the widget
    static let allEventsKey = "allEvents"
    
    init() {
        loadEvents()
        loadDisplaySettings()
        loadNotificationSettings()
        addDefaultYearTrackerIfNeeded()
    }
    
    public func getEvents() -> [Event] {
        return events
    }
        
    func findEventIndex(withId id: UUID) -> Int? {
        return events.firstIndex(where: { $0.id == id })
    }
    
    func saveEvent(_ event: Event) {
        // Check if this is a year tracker event
        let isYearTracker = event.title == String(Calendar.current.component(.year, from: Date()))
        
        // Count user-created events (excluding year tracker)
        let userEventCount = events.filter { $0.title != String(Calendar.current.component(.year, from: Date())) }.count
        
        // Get the event limit based on subscription status
        let eventLimit = PaymentManager.getEventLimit()
        
        // Only allow saving if it's a year tracker or if we haven't reached the limit
        if isYearTracker || userEventCount < eventLimit {
            if !events.contains(where: { $0.id == event.id }) {
                events.append(event)
                // Initialize display settings when saving a new event
                let newSettings = DisplaySettings()
                displaySettings[event.id] = newSettings
                // Initialize notification settings when saving a new event
                let newNotificationSettings = NotificationSettings()
                notificationSettings[event.id] = newNotificationSettings
                saveEvents()
                saveDisplaySettings()
                saveNotificationSettings()
                
                // If this is a year tracker, save it separately for widget access
                if isYearTracker {
                    saveYearTrackerForWidget(event)
                }
                
                // Save all events for widget access
                saveAllEventsForWidget()
                
                // Reload widget timeline
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }
    
    // Check if user can add more events
    func canAddMoreEvents() -> Bool {
        // Count user-created events (excluding year tracker)
        let userEventCount = events.filter { $0.title != String(Calendar.current.component(.year, from: Date())) }.count
        
        // Get the event limit based on subscription status
        let eventLimit = PaymentManager.getEventLimit()
        
        return userEventCount < eventLimit
    }
    
    // Get remaining event slots
    func remainingEventSlots() -> Int {
        // Count user-created events (excluding year tracker)
        let userEventCount = events.filter { $0.title != String(Calendar.current.component(.year, from: Date())) }.count
        
        // Get the event limit based on subscription status
        let eventLimit = PaymentManager.getEventLimit()
        
        return max(0, eventLimit - userEventCount)
    }
    
    // Check if user needs to subscribe to add more events
    func needsSubscriptionForMoreEvents() -> Bool {
        return !canAddMoreEvents() && !PaymentManager.isUserSubscribed()
    }
    
    func updateEvent(id: UUID, title: String, targetDate: Date, creationDate: Date) {
        if let index = events.firstIndex(where: { $0.id == id }) {
            // Create updated event with the same ID and new creation date
            let updatedEvent = Event(id: id, title: title, targetDate: targetDate, creationDate: creationDate)
            events[index] = updatedEvent
            // Display settings will be preserved since we're using the same ID
            saveEvents()
            saveDisplaySettings()
            
            // If this is the year tracker, update the widget data
            if title == String(Calendar.current.component(.year, from: Date())) {
                saveYearTrackerForWidget(updatedEvent)
            }
            
            // Update all events for widget access
            saveAllEventsForWidget()
            
            // Reload widget timeline
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        // Also remove display settings when deleting an event
        displaySettings.removeValue(forKey: event.id)
        saveEvents()
        saveDisplaySettings()
        
        // If this was the year tracker, we need to create a new one
        if event.title == String(Calendar.current.component(.year, from: Date())) {
            let newYearTracker = Event.defaultYearTracker()
            events.insert(newYearTracker, at: 0)
            saveEvents()
            saveYearTrackerForWidget(newYearTracker)
        }
        
        // Update all events for widget access
        saveAllEventsForWidget()
        
        // Reload widget timeline
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func loadEvents() {
        if let data = UserDefaults.shared?.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.shared?.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadDisplaySettings() {
        if let data = UserDefaults.shared?.data(forKey: displaySettingsKey),
           let decoded = try? JSONDecoder().decode([UUID: DisplaySettings].self, from: data) {
            displaySettings = decoded
            // Ensure all events have display settings
            for event in events {
                if displaySettings[event.id] == nil {
                    displaySettings[event.id] = DisplaySettings()
                }
            }
            saveDisplaySettings()
        } else {
            // Initialize display settings for all events if none exist
            for event in events {
                displaySettings[event.id] = DisplaySettings()
            }
            saveDisplaySettings()
        }
    }
    
    func saveDisplaySettings() {
        if let encoded = try? JSONEncoder().encode(displaySettings) {
            UserDefaults.shared?.set(encoded, forKey: displaySettingsKey)
        }
    }
    
    private func addDefaultYearTrackerIfNeeded() {
        let defaultEvent = Event.defaultYearTracker()
        if !events.contains(where: { $0.title == defaultEvent.title }) {
            events.insert(defaultEvent, at: 0)
            saveEvents()
            saveYearTrackerForWidget(defaultEvent)
            saveAllEventsForWidget()
        } else if let yearTracker = events.first(where: { $0.title == defaultEvent.title }) {
            // If year tracker exists, ensure it's also saved for the widget
            saveYearTrackerForWidget(yearTracker)
            saveAllEventsForWidget()
        }
    }
    
    // Save the year tracker event specifically for the widget
    private func saveYearTrackerForWidget(_ event: Event) {
        if let encoded = try? JSONEncoder().encode(event) {
            UserDefaults.shared?.set(encoded, forKey: EventStore.yearTrackerKey)
        }
    }
    
    // Save all events for the widget to access
    private func saveAllEventsForWidget() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.shared?.set(encoded, forKey: EventStore.allEventsKey)
        }
    }
    
    func updateNotificationSettings(for eventId: UUID, settings: NotificationSettings) {
        // Update the settings in the dictionary
        notificationSettings[eventId] = settings
        
        // Save to UserDefaults
        saveNotificationSettings()
        
        print("Updated notification settings for event \(eventId): \(settings)")
        print("Current notification settings dictionary: \(notificationSettings)")
        
        // Schedule notifications based on the new settings
        if let event = events.first(where: { $0.id == eventId }) {
            // Check if this is the year tracker
            let isYearTracker = event.title == String(Calendar.current.component(.year, from: Date()))
            
            // First, remove any existing notifications for this event
            NotificationManager.shared.removeNotifications(for: eventId)
            
            if settings.isEnabled {
                if isYearTracker && settings.milestoneNotificationsEnabled {
                    // Schedule special year tracker milestones
                    NotificationManager.shared.scheduleYearTrackerMilestones(for: event, with: settings)
                }
                
                // Schedule regular notifications
                NotificationManager.shared.scheduleNotifications(for: event, with: settings)
            }
        }
    }
    
    func getNotificationSettings(for eventId: UUID) -> NotificationSettings {
        let settings = notificationSettings[eventId] ?? NotificationSettings()
        print("Retrieved notification settings for event \(eventId): \(settings)")
        return settings
    }
    
    func deleteEvent(withId id: UUID) {
        if let index = findEventIndex(withId: id) {
            // Remove notifications for this event
            NotificationManager.shared.removeNotifications(for: id)
            
            // Remove the event and its settings
            events.remove(at: index)
            displaySettings.removeValue(forKey: id)
            notificationSettings.removeValue(forKey: id)
            
            saveEvents()
            saveDisplaySettings()
            saveNotificationSettings()
            
            // Save all events for widget access
            saveAllEventsForWidget()
            
            // Reload widget timeline
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Notification Settings Persistence
    
    private func saveNotificationSettings() {
        if let encoded = try? JSONEncoder().encode(notificationSettings) {
            UserDefaults.standard.set(encoded, forKey: notificationSettingsKey)
            
            // Synchronize UserDefaults to ensure data is written to disk
            UserDefaults.standard.synchronize()
            
            print("Saved notification settings to UserDefaults with key: \(notificationSettingsKey)")
            
            // Force a UI update
            objectWillChange.send()
        } else {
            print("Error: Failed to encode notification settings")
        }
    }
    
    private func loadNotificationSettings() {
        if let savedSettings = UserDefaults.standard.data(forKey: notificationSettingsKey) {
            do {
                let decodedSettings = try JSONDecoder().decode([UUID: NotificationSettings].self, from: savedSettings)
                notificationSettings = decodedSettings
                print("Successfully loaded notification settings from UserDefaults: \(notificationSettings)")
            } catch {
                print("Error decoding notification settings: \(error.localizedDescription)")
            }
        } else {
            print("No saved notification settings found in UserDefaults")
        }
    }
    
    // Get events based on subscription status
    func getEventsLimitedBySubscription() -> [Event] {
        // If the user is subscribed, return all events
        if PaymentManager.isUserSubscribed() {
            return events
        }
        
        // For free users, return the year tracker plus the allowed number of custom events
        let yearTracker = events.first { 
            $0.title == String(Calendar.current.component(.year, from: Date())) 
        }
        
        // Get the event limit from PaymentManager (1 for free users)
        let customEventLimit = PaymentManager.getEventLimit()
        
        // Get all non-year-tracker events
        let customEvents = events.filter { 
            $0.title != String(Calendar.current.component(.year, from: Date())) 
        }
        
        // Sort custom events by creation date (newest first) and take only up to the limit
        let allowedCustomEvents = customEvents
            .sorted(by: { $0.creationDate > $1.creationDate })
            .prefix(customEventLimit)
        
        // Combine year tracker with allowed custom events
        var result: [Event] = []
        if let yearTracker = yearTracker {
            result.append(yearTracker)
        }
        result.append(contentsOf: allowedCustomEvents)
        
        return result
    }
}
