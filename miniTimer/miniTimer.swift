//
//  miniTimer.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import SwiftUI

// Enhanced EventDataProvider to support fetching data for multiple events
class EventDataProvider {
    struct EventData {
        let daysLeft: Int
        let totalDays: Int
        let title: String
        let eventId: UUID? // Added to store the event ID for deep linking
    }
    
    static func getEventData(eventId: UUID?) -> EventData {
        // First try to find the specific selected event
        if let eventId = eventId {
            if let data = UserDefaults.shared?.data(forKey: "allEvents"),
               let events = try? JSONDecoder().decode([Event].self, from: data),
               let selectedEvent = events.first(where: { $0.id == eventId }) {
                
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
        if let data = UserDefaults.shared?.data(forKey: "yearTrackerEvent"),
           let event = try? JSONDecoder().decode(Event.self, from: data) {
            // Use the progressDetails method to calculate days left and total days
            let details = event.progressDetails()
            return EventData(
                daysLeft: details.daysLeft,
                totalDays: details.totalDays,
                title: event.title,
                eventId: event.id
            )
        }
        
        // Ultimate fallback to calculating days left in the current year
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let daysLeft = calendar.dateComponents([.day], from: today, to: endOfYear).day ?? 365
        
        return EventData(daysLeft: daysLeft, totalDays: 365, title: "\(year)", eventId: nil)
    }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let primaryData = EventDataProvider.getEventData(eventId: nil)
        let secondaryData = EventDataProvider.getEventData(eventId: nil)

        return SimpleEntry(
            date: Date(),
            primaryEventData: primaryData,
            secondaryEventData: secondaryData,
            configuration: ConfigurationAppIntent()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let primaryData = EventDataProvider.getEventData(eventId: configuration.selectedEvent?.id)
        let secondaryData = EventDataProvider.getEventData(eventId: configuration.secondaryEvent?.id)

        return SimpleEntry(
            date: Date(),
            primaryEventData: primaryData,
            secondaryEventData: secondaryData,
            configuration: configuration
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let primaryData = EventDataProvider.getEventData(eventId: configuration.selectedEvent?.id)
        let secondaryData = EventDataProvider.getEventData(eventId: configuration.secondaryEvent?.id)

        let entry = SimpleEntry(
            date: Date(),
            primaryEventData: primaryData,
            secondaryEventData: secondaryData,
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
    let primaryEventData: EventDataProvider.EventData
    let secondaryEventData: EventDataProvider.EventData
    let configuration: ConfigurationAppIntent
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

    // Create URL for deep linking to the specific event
    private func createDeepLink(for eventId: UUID?) -> URL? {
        guard let eventId = eventId else { return nil }
        return URL(string: "timelapse://event/\(eventId.uuidString)")
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
                                .foregroundColor(textColor)
                                .lineLimit(1)

                            Spacer()

                            HStack(spacing: 4) {
                                Text("\(entry.primaryEventData.daysLeft)")
                                    .font(.system(size: 8))

                                Text(entry.primaryEventData.daysLeft == 1 ? "day left" : "days left")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(textColor)
                        }
                    }
                    .accentColor(entry.configuration.displayColor.color)

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
                                .foregroundColor(textColor)
                                .lineLimit(1)

                            Spacer()

                            HStack(spacing: 4) {
                                Text("\(entry.secondaryEventData.daysLeft)")
                                    .font(.system(size: 8))

                                Text(entry.secondaryEventData.daysLeft == 1 ? "day left" : "days left")
                                    .font(.system(size: 8))
                            }
                            .foregroundColor(textColor)
                        }

                    }
                    .accentColor(entry.configuration.secondaryDisplayColor.color)
                }
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
                .accentColor(entry.configuration.displayColor.color)
                .widgetURL(createDeepLink(for: entry.primaryEventData.eventId))
            }

            // Bottom info bar - similar to main app (only for non-medium widgets since medium widgets now have in-place labels)
            if family != .systemMedium && (family != .systemSmall || entry.configuration.displayStyle != .countdown) {
                HStack {
                    Text(entry.primaryEventData.title)
                        .font(.system(size: family == .systemSmall ? 8 : 10))
                        .foregroundColor(textColor)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: family == .systemSmall ? 2 : 4) {
                        Text("\(entry.primaryEventData.daysLeft)")
                            .font(.system(size: family == .systemSmall ? 8 : 10))

                        Text(entry.primaryEventData.daysLeft == 1 ? "day left" : "days left")
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
    fileprivate static var preview: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.displayStyle = .dotPixels
        intent.secondaryDisplayStyle = .progressBar
        intent.displayColor = .orange
        intent.secondaryDisplayColor = .blue
        intent.backgroundTheme = .dark
        return intent
    }
}

#Preview(as: .systemSmall) {
    miniTimer()
} timeline: {
    let primaryData = EventDataProvider.EventData(daysLeft: 300, totalDays: 365, title: "2025", eventId: UUID())
    let secondaryData = EventDataProvider.EventData(daysLeft: 150, totalDays: 180, title: "Project X", eventId: UUID())
    
    SimpleEntry(date: .now, primaryEventData: primaryData, secondaryEventData: secondaryData, configuration: .preview)
}

#Preview(as: .systemMedium) {
    miniTimer()
} timeline: {
    let primaryData = EventDataProvider.EventData(daysLeft: 300, totalDays: 365, title: "2025", eventId: UUID())
    let secondaryData = EventDataProvider.EventData(daysLeft: 150, totalDays: 180, title: "Project X", eventId: UUID())

    SimpleEntry(date: .now, primaryEventData: primaryData, secondaryEventData: secondaryData, configuration: .preview)
}
