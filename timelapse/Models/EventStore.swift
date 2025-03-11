import Foundation

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    private let eventsKey = "savedEvents"
    @Published var displaySettings: [UUID: DisplaySettings] = [:]
    private let displaySettingsKey = "savedDisplaySettings"
    
    // The key for the year tracker event that will be shared with the widget
    static let yearTrackerKey = "yearTrackerEvent"
    // The key for all events that will be shared with the widget
    static let allEventsKey = "allEvents"
    
    init() {
        loadEvents()
        loadDisplaySettings()
        addDefaultYearTrackerIfNeeded()
    }
    
    func saveEvent(_ event: Event) {
        // Check if this is a year tracker event
        let isYearTracker = event.title == String(Calendar.current.component(.year, from: Date()))
        
        // Count user-created events (excluding year tracker)
        let userEventCount = events.filter { $0.title != String(Calendar.current.component(.year, from: Date())) }.count
        
        // Only allow saving if it's a year tracker or if we haven't reached the limit
        if isYearTracker || userEventCount < 5 {
            if !events.contains(where: { $0.id == event.id }) {
                events.append(event)
                // Initialize display settings when saving a new event
                let newSettings = DisplaySettings()
                displaySettings[event.id] = newSettings
                saveEvents()
                saveDisplaySettings()
                
                // If this is a year tracker, save it separately for widget access
                if isYearTracker {
                    saveYearTrackerForWidget(event)
                }
                
                // Save all events for widget access
                saveAllEventsForWidget()
            }
        }
    }
    
    func updateEvent(id: UUID, title: String, targetDate: Date) {
        if let index = events.firstIndex(where: { $0.id == id }) {
            // Create updated event with the same ID and creation date
            let updatedEvent = Event(id: id, title: title, targetDate: targetDate, creationDate: events[index].creationDate)
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
}
