//
//  miniTimer.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import SwiftUI

// Renamed class to better reflect its purpose - fetching event data for the widget
class EventDataProvider {
    static func getEventData(eventId: UUID?) -> (daysLeft: Int, totalDays: Int, title: String) {
        // First try to find the specific selected event
        if let eventId = eventId {
            if let data = UserDefaults.shared?.data(forKey: "allEvents"),
               let events = try? JSONDecoder().decode([Event].self, from: data),
               let selectedEvent = events.first(where: { $0.id == eventId }) {
                
                // Use the progressDetails method to calculate days left and total days
                let details = selectedEvent.progressDetails()
                return (details.daysLeft, details.totalDays, selectedEvent.title)
            }
        }
        
        // If no event ID specified or event not found, fall back to year tracker
        if let data = UserDefaults.shared?.data(forKey: "yearTrackerEvent"),
           let event = try? JSONDecoder().decode(Event.self, from: data) {
            // Use the progressDetails method to calculate days left and total days
            let details = event.progressDetails()
            return (details.daysLeft, details.totalDays, event.title)
        }
        
        // Ultimate fallback to calculating days left in the current year
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let daysLeft = calendar.dateComponents([.day], from: today, to: endOfYear).day ?? 365
        
        return (daysLeft, 365, "\(year)")
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let eventData = EventDataProvider.getEventData(eventId: nil)
        return SimpleEntry(
            date: Date(), 
            daysLeft: eventData.daysLeft, 
            totalDays: eventData.totalDays,
            title: eventData.title, 
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let eventData = EventDataProvider.getEventData(eventId: configuration.selectedEvent?.id)
        return SimpleEntry(
            date: Date(), 
            daysLeft: eventData.daysLeft, 
            totalDays: eventData.totalDays,
            title: eventData.title, 
            configuration: configuration
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Get data from the shared container for the selected event
        let eventData = EventDataProvider.getEventData(eventId: configuration.selectedEvent?.id)
        
        let entry = SimpleEntry(
            date: Date(), 
            daysLeft: eventData.daysLeft, 
            totalDays: eventData.totalDays,
            title: eventData.title, 
            configuration: configuration
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
    let daysLeft: Int
    let totalDays: Int
    let title: String
    let configuration: ConfigurationAppIntent
    
    var daysSpent: Int { totalDays - daysLeft }
}

struct miniTimerEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    private var textColor: Color {
        entry.configuration.backgroundTheme == .dark ? .white : .black
    }
    
    private var containerPadding: CGFloat {
        1 // Much smaller padding for a more compact widget design
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with display style
            if family == .systemMedium {
                HStack(spacing: 16) {
                    // Primary display
                    ZStack {
                        switch entry.configuration.displayStyle {
                        case .dotPixels:
                            DotPixelsWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                        case .triGrid:
                            TriGridWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                        case .progressBar:
                            ProgressBarWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                        case .countdown:
                            CountdownWidgetView(daysLeft: entry.daysLeft, family: family)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Secondary display
                    ZStack {
                        switch entry.configuration.secondaryDisplayStyle {
                        case .dotPixels:
                            DotPixelsWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                        case .triGrid:
                            TriGridWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                        case .progressBar:
                            ProgressBarWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                        case .countdown:
                            CountdownWidgetView(daysLeft: entry.daysLeft, family: family)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Single display for small and large widgets
                ZStack {
                    switch entry.configuration.displayStyle {
                    case .dotPixels:
                        DotPixelsWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                    case .triGrid:
                        TriGridWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                    case .progressBar:
                        ProgressBarWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                    case .countdown:
                        CountdownWidgetView(daysLeft: entry.daysLeft, family: family)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Bottom info bar - similar to main app
            if family != .systemSmall || entry.configuration.displayStyle != .countdown {
                HStack {
                    Text(entry.title)
                        .font(.system(size: family == .systemSmall ? 8 : 10, weight: .medium))
                        .foregroundColor(textColor)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: family == .systemSmall ? 2 : 4) {
                        Text("\(entry.daysLeft)")
                            .font(.system(size: family == .systemSmall ? 10 : 12, weight: .semibold))
                        
                        Text("days left")
                            .font(.system(size: family == .systemSmall ? 8 : 10))
                    }
                    .foregroundColor(textColor)
                }
            }
        }
        .accentColor(entry.configuration.displayColor.color)
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
        .description("Track the days of your events with various display styles.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var preview: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.displayStyle = .dotPixels
        intent.displayColor = .orange
        intent.backgroundTheme = .dark
        return intent
    }
}

#Preview(as: .systemSmall) {
    miniTimer()
} timeline: {
    SimpleEntry(date: .now, daysLeft: 300, totalDays: 365, title: "2025", configuration: .preview)
}
