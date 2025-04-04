//
//  miniTimer.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import SwiftUI
import Intents

// Enhanced EventDataProvider to support fetching data for multiple events
class EventDataProvider {
    struct EventData {
        let daysLeft: Int
        let totalDays: Int
        let title: String
        let eventId: UUID? // Added to store the event ID for deep linking
    }
    
    static func getEventData(eventId: UUID?) -> EventData {
        // Check if user is subscribed
        let isSubscribed = isUserSubscribed()
        
        // First try to find the specific selected event (for subscribers only)
        if let eventId = eventId {
            if let data = UserDefaults.shared?.data(forKey: "allEvents"),
               let events = try? JSONDecoder().decode([Event].self, from: data),
               let selectedEvent = events.first(where: { $0.id == eventId }) {
                
                // If user is not subscribed, only allow year tracker
                if !isSubscribed && !isYearTracker(selectedEvent) {
                    return getYearTrackerData()
                }
                
                // Use the progressDetails method to calculate days left and total days
                let details = selectedEvent.progressDetails()
                return EventData(
                    daysLeft: details.daysLeft,
                    totalDays: details.totalDays,
                    title: selectedEvent.title,
                    eventId: eventId
                )
            }
        }
        
        // If no event ID specified or event not found, fall back to year tracker
        return getYearTrackerData()
    }
    
    // Helper function to get the year tracker data
    private static func getYearTrackerData() -> EventData {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        if let data = UserDefaults.shared?.data(forKey: "yearTrackerEvent"),
           let yearEvent = try? JSONDecoder().decode(Event.self, from: data) {
            let details = yearEvent.progressDetails()
            return EventData(
                daysLeft: details.daysLeft,
                totalDays: details.totalDays,
                title: yearEvent.title,
                eventId: yearEvent.id
            )
        }
        
        // If no year tracker found, create a default one
        let defaultYearEvent = Event(title: "\(currentYear)", targetDate: calendar.date(from: DateComponents(year: currentYear + 1, month: 1, day: 1))!)
        let details = defaultYearEvent.progressDetails()
        return EventData(
            daysLeft: details.daysLeft,
            totalDays: details.totalDays,
            title: defaultYearEvent.title,
            eventId: defaultYearEvent.id
        )
    }
    
    // Helper function to check if an event is the year tracker
    private static func isYearTracker(_ event: Event) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return event.title == "\(currentYear)"
    }
    
    // Helper function to check subscription status
    private static func isUserSubscribed() -> Bool {
        return UserDefaults.shared?.bool(forKey: "isSubscribed") ?? false
    }
}

struct Provider: AppIntentTimelineProvider {
    // Store the timestamp of the last color update to force widget refreshes
    private var lastColorUpdateTimestamp: Date {
        if let timestamp = UserDefaults.shared?.object(forKey: "lastColorUpdateTimestamp") as? Date {
            return timestamp
        }
        return Date.distantPast
    }
    
    func placeholder(in context: Context) -> SimpleEntry {
        let primaryData = EventDataProvider.getEventData(eventId: nil)
        let secondaryData = EventDataProvider.getEventData(eventId: nil)

        return SimpleEntry(
            date: Date(),
            primaryEventData: primaryData,
            secondaryEventData: secondaryData,
            configuration: ConfigurationAppIntent(),
            colorUpdateTimestamp: lastColorUpdateTimestamp
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let primaryData = EventDataProvider.getEventData(eventId: configuration.selectedEvent?.id)
        let secondaryData = EventDataProvider.getEventData(eventId: configuration.secondaryEvent?.id)

        return SimpleEntry(
            date: Date(),
            primaryEventData: primaryData,
            secondaryEventData: secondaryData,
            configuration: configuration,
            colorUpdateTimestamp: lastColorUpdateTimestamp
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let primaryData = EventDataProvider.getEventData(eventId: configuration.selectedEvent?.id)
        let secondaryData = EventDataProvider.getEventData(eventId: configuration.secondaryEvent?.id)

        let entry = SimpleEntry(
            date: Date(),
            primaryEventData: primaryData,
            secondaryEventData: secondaryData,
            configuration: configuration,
            colorUpdateTimestamp: lastColorUpdateTimestamp
        )

        // Update at midnight
        let calendar = Calendar.current
        let today = Date()
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: today)!)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let primaryEventData: EventDataProvider.EventData
    let secondaryEventData: EventDataProvider.EventData
    let configuration: ConfigurationAppIntent
    let colorUpdateTimestamp: Date
}

// Helper extension to get color from ColorEntity
extension ColorEntity {
    var color: Color {
        Color(hex: hexValue)
    }
    
    // Get a default orange color entity if none is specified
    static var defaultOrange: ColorEntity {
        ColorEntity(id: "orange", name: "Orange", hexValue: "FF7F00")
    }
    
    // Get a default blue color entity if none is specified
    static var defaultBlue: ColorEntity {
        ColorEntity(id: "blue", name: "Blue", hexValue: "018AFB")
    }
}

struct miniTimerEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    // Get primary display color, with fallback to default orange
    private var primaryColor: Color {
        entry.configuration.displayColor?.color ?? ColorEntity.defaultOrange.color
    }
    
    // Get secondary display color, with fallback to default blue
    private var secondaryColor: Color {
        entry.configuration.secondaryDisplayColor?.color ?? ColorEntity.defaultBlue.color
    }

    private var textColor: Color {
        entry.configuration.backgroundTheme == .dark ? .white : .black
    }

    private var containerPadding: CGFloat {
        0 // No padding for maximum space utilization in widget design
    }

    // Create URL for deep linking to the specific event
    private func createDeepLink(for eventId: UUID?) -> URL? {
        guard let eventId = eventId else { return nil }
        return URL(string: "timelapse://event/\(eventId.uuidString)")
    }
    
    // Helper function to get appropriate days text based on daysLeft value
    private func daysLeftText(_ daysLeft: Int) -> String {
        if daysLeft < 0 {
            let daysPassed = abs(daysLeft)
            return daysPassed == 1 ? "day ago" : "days ago"
        } else if daysLeft == 0 {
            return "It's Today"
        } else if daysLeft == 1 {
            return "day left"
        } else {
            return "days left"
        }
    }
    
    // Helper function to determine if we should show the days count
    private func shouldShowDaysCount(_ daysLeft: Int) -> Bool {
        return daysLeft != 0 // Show count for both future and overdue events
    }

    var body: some View {
        VStack(spacing: 0) {
            // Main content area with display style
            if family == .systemMedium {
                HStack(spacing: 16) {
                    // Primary display - Left side
                    VStack(spacing: 0) {
                        ZStack {
                            switch entry.configuration.displayStyle {
                            case .dotPixels:
                                DotPixelsWidgetView(
                                    daysLeft: entry.primaryEventData.daysLeft,
                                    totalDays: entry.primaryEventData.totalDays,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            case .triGrid:
                                TriGridWidgetView(
                                    daysLeft: entry.primaryEventData.daysLeft,
                                    totalDays: entry.primaryEventData.totalDays,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            case .progressBar:
                                ProgressBarWidgetView(
                                    daysLeft: entry.primaryEventData.daysLeft,
                                    totalDays: entry.primaryEventData.totalDays,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            case .countdown:
                                CountdownWidgetView(
                                    daysLeft: entry.primaryEventData.daysLeft,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .widgetURL(createDeepLink(for: entry.primaryEventData.eventId))

                        // Primary info bar
                        HStack {
                            Text(entry.primaryEventData.title)
                                .font(.system(size: 8))
                                .foregroundColor(primaryColor)
                                .lineLimit(1)

                            Spacer()

                            HStack(spacing: 4) {
                                if shouldShowDaysCount(entry.primaryEventData.daysLeft) {
                                    Text("\(abs(entry.primaryEventData.daysLeft))")
                                        .font(.system(size: 8))
                                }

                                Text(daysLeftText(entry.primaryEventData.daysLeft))
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(textColor)
                        }
                    }
                    .accentColor(primaryColor)

                    // Secondary display - Right side
                    VStack(spacing: 0) {
                        ZStack {
                            switch entry.configuration.secondaryDisplayStyle {
                            case .dotPixels:
                                DotPixelsWidgetView(
                                    daysLeft: entry.secondaryEventData.daysLeft,
                                    totalDays: entry.secondaryEventData.totalDays,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            case .triGrid:
                                TriGridWidgetView(
                                    daysLeft: entry.secondaryEventData.daysLeft,
                                    totalDays: entry.secondaryEventData.totalDays,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            case .progressBar:
                                ProgressBarWidgetView(
                                    daysLeft: entry.secondaryEventData.daysLeft,
                                    totalDays: entry.secondaryEventData.totalDays,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            case .countdown:
                                CountdownWidgetView(
                                    daysLeft: entry.secondaryEventData.daysLeft,
                                    family: family,
                                    backgroundTheme: entry.configuration.backgroundTheme
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .widgetURL(createDeepLink(for: entry.secondaryEventData.eventId))

                        // Secondary info bar
                        HStack {
                            Text(entry.secondaryEventData.title)
                                .font(.system(size: 8))
                                .foregroundColor(secondaryColor)
                                .lineLimit(1)

                            Spacer()

                            HStack(spacing: 4) {
                                if shouldShowDaysCount(entry.secondaryEventData.daysLeft) {
                                    Text("\(abs(entry.secondaryEventData.daysLeft))")
                                        .font(.system(size: 8))
                                }

                                Text(daysLeftText(entry.secondaryEventData.daysLeft))
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(textColor)
                        }

                    }
                    .accentColor(secondaryColor)
                }
                .padding(containerPadding)
                .background(
                    entry.configuration.backgroundTheme == .dark ?
                        Color.black :
                        Color.white
                )
            } else {
                // Single display for small and large widgets
                ZStack {
                    switch entry.configuration.displayStyle {
                    case .dotPixels:
                        DotPixelsWidgetView(
                            daysLeft: entry.primaryEventData.daysLeft,
                            totalDays: entry.primaryEventData.totalDays,
                            family: family,
                            backgroundTheme: entry.configuration.backgroundTheme
                        )
                    case .triGrid:
                        TriGridWidgetView(
                            daysLeft: entry.primaryEventData.daysLeft,
                            totalDays: entry.primaryEventData.totalDays,
                            family: family,
                            backgroundTheme: entry.configuration.backgroundTheme
                        )
                    case .progressBar:
                        ProgressBarWidgetView(
                            daysLeft: entry.primaryEventData.daysLeft,
                            totalDays: entry.primaryEventData.totalDays,
                            family: family,
                            backgroundTheme: entry.configuration.backgroundTheme
                        )
                    case .countdown:
                        CountdownWidgetView(
                            daysLeft: entry.primaryEventData.daysLeft,
                            family: family,
                            backgroundTheme: entry.configuration.backgroundTheme
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accentColor(primaryColor)
                .widgetURL(createDeepLink(for: entry.primaryEventData.eventId))
            }

            // Bottom info bar - similar to main app (only for non-medium widgets since medium widgets now have in-place labels)
            if family != .systemMedium {
                HStack {
                    Text(entry.primaryEventData.title)
                        .font(.system(size: family == .systemSmall ? 8 : 10))
                        .foregroundColor(primaryColor)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: family == .systemSmall ? 2 : 4) {
                        if shouldShowDaysCount(entry.primaryEventData.daysLeft) {
                            Text("\(abs(entry.primaryEventData.daysLeft))")
                                .font(.system(size: family == .systemSmall ? 8 : 10))
                        }

                        Text(daysLeftText(entry.primaryEventData.daysLeft))
                            .font(.system(size: family == .systemSmall ? 8 : 10))
                    }
                    .foregroundColor(textColor)
                }
            }
        }
        .padding(containerPadding)
    }
}

struct miniTimer: Widget {
    let kind: String = "miniTimer"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            miniTimerEntryView(entry: entry)
                .containerBackground(entry.configuration.backgroundTheme == .light ? .white : .black, for: .widget)
        }
        .configurationDisplayName("Event Tracker")
        .description("Customize your Experience")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    static var preview: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.displayStyle = .dotPixels
        intent.secondaryDisplayStyle = .progressBar 
        intent.displayColor = ColorEntity.defaultOrange
        intent.secondaryDisplayColor = ColorEntity.defaultBlue
        intent.backgroundTheme = .dark
        return intent
    }
}

#Preview(as: .systemSmall) {
    miniTimer()
} timeline: {
    let primaryData = EventDataProvider.EventData(daysLeft: 300, totalDays: 365, title: "2025", eventId: UUID())
    let secondaryData = EventDataProvider.EventData(daysLeft: 150, totalDays: 180, title: "Project X", eventId: UUID())
    
    SimpleEntry(date: .now, primaryEventData: primaryData, secondaryEventData: secondaryData, configuration: .preview, colorUpdateTimestamp: Date())
}

#Preview(as: .systemMedium) {
    miniTimer()
} timeline: {
    let primaryData = EventDataProvider.EventData(daysLeft: 300, totalDays: 365, title: "2025", eventId: UUID())
    let secondaryData = EventDataProvider.EventData(daysLeft: 150, totalDays: 180, title: "Project X", eventId: UUID())

    SimpleEntry(date: .now, primaryEventData: primaryData, secondaryEventData: secondaryData, configuration: .preview, colorUpdateTimestamp: Date())
}
