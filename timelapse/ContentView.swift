//
//  ContentView.swift
//  timelapse
//
//  Created by Wan Menzy on 2/18/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var eventStore = EventStore()
    @StateObject private var globalSettings = GlobalSettings()
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentDate = Date()
    @State private var selectedTab = 0
    @State private var yearTrackerSettings: DisplaySettings = DisplaySettings(backgroundStyle: .dark)
  
    private func settings(for event: Event) -> DisplaySettings {
        if event.title == String(currentYear) {
            return yearTrackerSettings
        }
        if eventStore.displaySettings[event.id] == nil {
            // Create and persist new settings if they don't exist
            let newSettings = DisplaySettings(backgroundStyle: globalSettings.effectiveBackgroundStyle)
            eventStore.displaySettings[event.id] = newSettings
            eventStore.saveDisplaySettings() // Save when creating new settings
        }
        let settings = eventStore.displaySettings[event.id]!
        settings.updateColor(for: globalSettings.effectiveBackgroundStyle)
        return settings
    }
    
    private func updateAllColors(for backgroundStyle: BackgroundStyle) {
        yearTrackerSettings.updateColor(for: backgroundStyle)
        for settings in eventStore.displaySettings.values {
            settings.updateColor(for: backgroundStyle)
        }
        eventStore.saveDisplaySettings()
    }
    
    private func scheduleNextUpdate() {
        let calendar = Calendar.current
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date())),
              let midnight = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + midnight.timeIntervalSince(Date())) {
            currentDate = Date()
            scheduleNextUpdate()
        }
    }
    
    var daysLeft: Int {
        let calendar = Calendar.current
        let today = currentDate
        let endOfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: today) + 1))!
        return calendar.dateComponents([.day], from: today, to: endOfYear).day ?? 0
    }
    
    var currentYear: Int {
        Calendar.current.component(.year, from: currentDate)
    }
    
    private var displayedEvents: [Event] {
        // Always put year tracker first, then other events
        let yearTracker = eventStore.events.first { $0.title == String(currentYear) }
        let otherEvents = eventStore.events.filter { $0.title != String(currentYear) }
        return [yearTracker].compactMap { $0 } + otherEvents
    }
    
    private var backgroundView: some View {
        Group {
            switch globalSettings.effectiveBackgroundStyle {
            case .light:
                Color.white
            case .dark:
                Color(hex: "111111")
            case .device: 
                colorScheme == .dark ? Color(hex: "111111") : Color.white
            case .navy:
                Color(hex: "001524")
            case .fire:
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "EC5F01"), location: 0),
                        .init(color: Color.black, location: 0.6),
                        .init(color: .black, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .dream:
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "A82700"), location: 0),
                        .init(color: Color(hex: "002728"), location: 0.6),
                        .init(color: Color(hex: "002728"), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            if globalSettings.showGridLayout {
                TimelineGridView(eventStore: eventStore, yearTrackerSettings: yearTrackerSettings, selectedTab: $selectedTab)
                    .environmentObject(globalSettings)
            } else {
                GeometryReader { geometry in
                    TabView(selection: $selectedTab) {
                        ForEach(Array(displayedEvents.enumerated()), id: \.element.id) { index, event in
                            let progress = event.progressDetails()
                            let eventSettings = settings(for: event)
                            
                            TimeCard(
                                title: event.title,
                                event: event,
                                settings: eventSettings,
                                eventStore: eventStore,
                                daysLeft: progress.daysLeft,
                                totalDays: progress.totalDays,
                                isGridView: false,
                                selectedTab: $selectedTab
                            )
                            .frame(width: geometry.size.width * 0.76)
                            .offset(y: -40) // Move the card up by 40 points
                            .tag(index)
                            .environmentObject(globalSettings)
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: selectedTab) { oldValue, newValue in
                    withAnimation {
                        selectedTab = min(max(newValue, 0), displayedEvents.count - 1)
                    }
                }
            }
        }
    }
    
    private var navigationContent: some View {
        VStack(spacing: 8) {
            // Page control dots
            if !globalSettings.showGridLayout {
                HStack(spacing: 6) {
                    ForEach(0..<displayedEvents.count, id: \.self) { index in
                        let distance = abs(selectedTab - index)
                        let size: CGFloat = distance == 0 ? 6 : max(4, 6 - CGFloat(distance))
                        let opacity: Double = distance == 0 ? 1 : max(0.3, 1 - Double(distance) * 0.2)
                        
                        Circle()
                            .fill(selectedTab == index ? 
                                 (globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white) :
                                 (globalSettings.effectiveBackgroundStyle == .light ? Color.black.opacity(opacity) : Color.white.opacity(opacity)))
                            .frame(width: size, height: size)
                    }
                }
                .animation(.easeInOut, value: selectedTab)
                .padding(.bottom, 8)
            }
            
            // Navigation bar
            NavigationBar()
        }
        .padding(.bottom, 40) // Added bottom padding to move navigation up
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            backgroundView
            timelineContent
            navigationContent
        }
        .onChange(of: globalSettings.backgroundStyle) { oldStyle, newStyle in
            updateAllColors(for: newStyle)
        }
        .onChange(of: colorScheme) { oldColorScheme, newColorScheme in
            globalSettings.updateSystemAppearance(newColorScheme == .dark)
        }
        .onAppear {
            currentDate = Date()
            scheduleNextUpdate()
            globalSettings.updateSystemAppearance(colorScheme == .dark)
        }
        .sheet(isPresented: $navigationState.showingCustomize) {
            if let event = displayedEvents[safe: selectedTab] {
                CustomizeView(settings: settings(for: event), eventStore: eventStore)
                    .environmentObject(globalSettings)
            }
        }
        .sheet(isPresented: $navigationState.showingTrackEvent) {
            TrackEventView(eventStore: eventStore, selectedTab: $selectedTab)
        }
        .sheet(isPresented: $navigationState.showingSettings) {
            SettingsView()
                .environmentObject(globalSettings)
        }
    }
}

// Add this extension to safely access array elements
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalSettings()) // Provide global settings
}
