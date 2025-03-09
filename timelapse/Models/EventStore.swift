import Foundation

class EventStore: ObservableObject {
    @Published var events: [Event] = []
    @Published var displaySettings: [UUID: DisplaySettings] = [:]
    
    // Use shared data manager for persistence
    private let sharedDataManager = SharedDataManager.shared
    
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
        if let loadedEvents = sharedDataManager.loadEvents() {
            events = loadedEvents
        }
    }
    
    func saveEvents() {
        sharedDataManager.saveEvents(events)
        updateYearTrackerInfo()
    }
    
    private func loadDisplaySettings() {
        if let loadedSettings = sharedDataManager.loadDisplaySettings() {
            displaySettings = loadedSettings
        }
        
        // Ensure all events have display settings
        for event in events {
            if displaySettings[event.id] == nil {
                displaySettings[event.id] = DisplaySettings()
            }
        }
        saveDisplaySettings()
    }
    
    func saveDisplaySettings() {
        sharedDataManager.saveDisplaySettings(displaySettings)
        updateWidgetPreferences()
    }
    
    private func addDefaultYearTrackerIfNeeded() {
        let defaultEvent = Event.defaultYearTracker()
        if !events.contains(where: { $0.title == defaultEvent.title }) {
            events.insert(defaultEvent, at: 0)
            saveEvents()
        }
    }
    
    // Save year tracker information specifically for the widget
    private func updateYearTrackerInfo() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearString = String(currentYear)
        
        // Find the year tracker event
        if let yearTracker = events.first(where: { $0.title == yearString }) {
            let progress = yearTracker.progressDetails()
            sharedDataManager.saveYearTrackerInfo(daysLeft: progress.daysLeft, totalDays: progress.totalDays)
        }
    }
    
    // Update widget preferences when display settings change
    private func updateWidgetPreferences() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        let yearString = String(currentYear)
        
        // Find the year tracker event and its settings
        if let yearTracker = events.first(where: { $0.title == yearString }),
           let settings = displaySettings[yearTracker.id] {
            sharedDataManager.saveWidgetPreferences(
                style: settings.style,
                showPercentage: settings.showPercentage,
                backgroundStyle: settings.backgroundStyle,
                displayColor: settings.displayColor
            )
        }
    }
}
