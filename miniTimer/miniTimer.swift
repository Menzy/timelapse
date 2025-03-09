//
//  miniTimer.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    // Use shared data manager to access app data
    private let sharedDataManager = SharedDataManager.shared
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(), 
            daysLeft: 365, 
            totalDays: 365, 
            configuration: ConfigurationAppIntent(),
            lastModified: Date()
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // Get the actual data from shared container
        let yearInfo = sharedDataManager.getYearTrackerInfo()
        let lastModified = sharedDataManager.getLastModified() ?? Date()
        
        // Always apply main app settings
        let updatedConfig = applyMainAppSettings(to: configuration)
        
        return SimpleEntry(
            date: Date(),
            daysLeft: yearInfo.daysLeft,
            totalDays: yearInfo.totalDays,
            configuration: updatedConfig,
            lastModified: lastModified
        )
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        // Get year tracker info from the shared container
        let yearInfo = sharedDataManager.getYearTrackerInfo()
        let lastModified = sharedDataManager.getLastModified() ?? Date()
        
        // Always apply main app settings
        let updatedConfig = applyMainAppSettings(to: configuration)
        
        let entry = SimpleEntry(
            date: Date(),
            daysLeft: yearInfo.daysLeft,
            totalDays: yearInfo.totalDays,
            configuration: updatedConfig,
            lastModified: lastModified
        )
        
        // Update at midnight to ensure the day count is correct
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        
        // Also check for updates every 15 minutes to detect changes in the main app
        let refreshDate = Date().addingTimeInterval(15 * 60)
        let nextUpdate = min(midnight, refreshDate)
        
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
    
    private func applyMainAppSettings(to configuration: ConfigurationAppIntent) -> ConfigurationAppIntent {
        // Get preferences from shared storage
        let prefs = sharedDataManager.getWidgetPreferences()
        var updatedConfig = configuration
        
        if let styleString = prefs.style,
           let style = DisplayStyleChoice(rawValue: styleString) {
            updatedConfig.displayStyle = style
        }
        
        if let backgroundStyleString = prefs.backgroundStyle {
            updatedConfig.backgroundTheme = backgroundStyleString == "light" ? .light : .dark
        }
        
        // Set color if available from main app
        if let colorComponents = prefs.displayColor,
           colorComponents.count >= 4 {
            // Find the closest preset color
            let r = colorComponents[0]
            let g = colorComponents[1]
            let b = colorComponents[2]
            
            // Orange: FF7F00 -> r=1.0, g=0.5, b=0
            // Blue: 008CFF/018AFB -> r=0, g=0.54, b=1.0
            // Green: 7FBF54 -> r=0.5, g=0.75, b=0.33
            
            // Calculate color distances (simple Euclidean distance)
            let orangeDist = sqrt(pow(r-1.0, 2) + pow(g-0.5, 2) + pow(b-0, 2))
            let blueDist = sqrt(pow(r-0, 2) + pow(g-0.54, 2) + pow(b-1.0, 2))
            let greenDist = sqrt(pow(r-0.5, 2) + pow(g-0.75, 2) + pow(b-0.33, 2))
            
            // Find the minimum distance
            let minDist = min(orangeDist, min(blueDist, greenDist))
            
            if minDist == orangeDist {
                updatedConfig.displayColor = .orange
            } else if minDist == blueDist {
                updatedConfig.displayColor = .blue
            } else {
                updatedConfig.displayColor = .green
            }
        }
        
        return updatedConfig
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let daysLeft: Int
    let totalDays: Int
    let configuration: ConfigurationAppIntent
    let lastModified: Date
    
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
        family == .systemSmall ? 5 : 10
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area with display style
            ZStack {
                switch entry.configuration.displayStyle {
                case .dotPixels:
                    DotPixelsWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family)
                case .triGrid:
                    TriGridWidgetView(daysLeft: entry.daysLeft, totalDays: entry.totalDays, family: family)
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
                .padding(.horizontal, family == .systemSmall ? 8 : 14)
                .padding(.vertical, family == .systemSmall ? 4 : 8)
            }
        }
        .accentColor(entry.configuration.displayColor.color)
        .padding(containerPadding)
        .background(entry.configuration.backgroundTheme == .light ? Color.white : Color.black)
        // Use last modified date to force view updates when app data changes
        .id(entry.lastModified)
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
        .description("Track the days of the year synced with the main app.")
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
    SimpleEntry(
        date: .now, 
        daysLeft: 300, 
        totalDays: 365, 
        configuration: .preview, 
        lastModified: Date()
    )
}
