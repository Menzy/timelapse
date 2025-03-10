//
//  miniTimer.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), daysLeft: 365, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), daysLeft: 365, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Calculate days left in the year
        let calendar = Calendar.current
        let today = Date()
        let year = calendar.component(.year, from: today)
        let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
        let daysLeft = calendar.dateComponents([.day], from: today, to: endOfYear).day!
        
        let entry = SimpleEntry(date: today, daysLeft: daysLeft, configuration: configuration)
        
        // Update at midnight
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: today)!)
        return Timeline(entries: [entry], policy: .after(midnight))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int
    let configuration: ConfigurationAppIntent
    
    var daysSpent: Int { 365 - daysLeft }
    var totalDays: Int { 365 }
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
            ZStack {
                switch entry.configuration.displayStyle {
                case .dotPixels:
                    DotPixelsWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                case .triGrid:
                    TriGridWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family, backgroundTheme: entry.configuration.backgroundTheme)
                case .progressBar:
                    ProgressBarWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family)
                case .countdown:
                    CountdownWidgetView(daysLeft: entry.daysLeft, family: family)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Bottom info bar - similar to main app
            if family != .systemSmall || entry.configuration.displayStyle != .countdown {
                HStack {
                    Text(String(Calendar.current.component(.year, from: Date())))
                        .font(.system(size: family == .systemSmall ? 8 : 10, weight: .medium))
                        .foregroundColor(textColor)
                    
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
        .configurationDisplayName("Year Tracker")
        .description("Track the days of the year with various display styles.")
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
    SimpleEntry(date: .now, daysLeft: 300, configuration: .preview)
}
