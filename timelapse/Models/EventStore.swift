import Foundation

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    private let eventsKey = "savedEvents"
    @Published var displaySettings: [UUID: DisplaySettings] = [:]
    private let displaySettingsKey = "savedDisplaySettings"
    
    init() {
        loadEvents()
        loadDisplaySettings()
        addDefaultYearTrackerIfNeeded()
    }
    
    func saveEvent(_ event: Event) {
        if !events.contains(where: { $0.id == event.id }) {
            events.append(event)
            // Initialize display settings when saving a new event
            let newSettings = DisplaySettings()
            displaySettings[event.id] = newSettings
            saveEvents()
            saveDisplaySettings()
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
        }
    }
    
    func deleteEvent(_ event: Event) {
        events.removeAll { $0.id == event.id }
        // Also remove display settings when deleting an event
        displaySettings.removeValue(forKey: event.id)
        saveEvents()
        saveDisplaySettings()
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            events = decoded
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    private func loadDisplaySettings() {
        if let data = UserDefaults.standard.data(forKey: displaySettingsKey),
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
    
    private func saveDisplaySettings() {
        if let encoded = try? JSONEncoder().encode(displaySettings) {
            UserDefaults.standard.set(encoded, forKey: displaySettingsKey)
        }
    }
    
    private func addDefaultYearTrackerIfNeeded() {
        let defaultEvent = Event.defaultYearTracker()
        if !events.contains(where: { $0.title == defaultEvent.title }) {
            events.insert(defaultEvent, at: 0)
            saveEvents()
        }
    }
}
