//
//  ContentView.swift
//  timelapse
//
//  Created by Wan Menzy on 2/18/25.
//

import SwiftUI
import Combine

// Add this extension to safely access array elements
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

struct ContentView: View {
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var eventStore = EventStore()
    @StateObject private var globalSettings = GlobalSettings()
    @StateObject private var paymentManager = PaymentManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentDate = Date()
    @State private var yearTrackerSettings: DisplaySettings = DisplaySettings(backgroundStyle: .dark)
    @State private var showSubscriptionView = false
    @State private var isAnimatingLayout = false
    
    // Animation states
    @State private var previousBackgroundStyle: BackgroundStyle?
    @State private var isAnimatingThemeChange: Bool = false
    @State private var themeChangeProgress: CGFloat = 0.0
    
    // Store all notification cancellables
    @State private var cancellables = Set<AnyCancellable>()
    
    private var displayedEvents: [Event] {
        // Always put year tracker first, then other events
        let yearTracker = eventStore.events.first { $0.title == YearTrackerUtility.currentYearTitle }
        let otherEvents = eventStore.events.filter { $0.title != YearTrackerUtility.currentYearTitle }
        return [yearTracker].compactMap { $0 } + otherEvents
    }
    
    private func settings(for event: Event) -> DisplaySettings {
        if event.title == YearTrackerUtility.currentYearTitle {
            // Return the year tracker settings
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
    
    private var timelineContent: some View {
        VStack(spacing: 0) {
            if globalSettings.showGridLayout {
                if paymentManager.isSubscribed {
                    // Subscribed user can see grid view
                    TimelineGridView(eventStore: eventStore, yearTrackerSettings: yearTrackerSettings, selectedTab: $navigationState.selectedTab)
                        .environmentObject(globalSettings)
                        .transition(
                            .asymmetric(
                                insertion: .scale(scale: 0.95)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3)),
                                removal: .scale(scale: 1.05)
                                    .combined(with: .opacity)
                                    .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3))
                            )
                        )
                } else {
                    // Non-subscribed user trying to use grid view
                    // Reset the grid layout setting and show subscription prompt
                    GeometryReader { geometry in
                        VStack {
                            // Default to tab view but also show subscription prompt
                            TabView(selection: $navigationState.selectedTab) {
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
                                        selectedTab: $navigationState.selectedTab
                                    )
                                    .frame(width: geometry.size.width * 0.76)
                                    .offset(y: -40)
                                    .tag(index)
                                    .environmentObject(globalSettings)
                                    .transition(
                                        .asymmetric(
                                            insertion: .scale(scale: 1.05)
                                                .combined(with: .opacity)
                                                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3)),
                                            removal: .scale(scale: 0.95)
                                                .combined(with: .opacity)
                                                .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3))
                                        )
                                    )
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        }
                        .onAppear {
                            // Reset the setting and trigger subscription view
                            DispatchQueue.main.async {
                                globalSettings.showGridLayout = false
                                showSubscriptionView = true
                            }
                        }
                    }
                }
            } else {
                // Standard tab view for all users
                GeometryReader { geometry in
                    TabView(selection: $navigationState.selectedTab) {
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
                                selectedTab: $navigationState.selectedTab
                            )
                            .frame(width: geometry.size.width * 0.76)
                            .offset(y: -40)
                            .tag(index)
                            .environmentObject(globalSettings)
                            .transition(
                                .asymmetric(
                                    insertion: .scale(scale: 1.05)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3)),
                                    removal: .scale(scale: 0.95)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0.3))
                                )
                            )
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .onChange(of: navigationState.selectedTab) { oldValue, newValue in
                    withAnimation {
                        navigationState.selectedTab = min(max(newValue, 0), displayedEvents.count - 1)
                    }
                }
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background with transition animation
            BackgroundView(
                isAnimating: isAnimatingThemeChange,
                previousStyle: previousBackgroundStyle,
                progress: themeChangeProgress
            )
            .environmentObject(globalSettings)
            
            // Main content
            timelineContent
            
            // Navigation with page indicators
            NavigationContentView(
                selectedTab: navigationState.selectedTab,
                eventCount: displayedEvents.count
            )
            .environmentObject(globalSettings)
        }
        .onChange(of: globalSettings.backgroundStyle) { oldStyle, newStyle in
            updateAllColors(for: newStyle)
            
            // Trigger blob animation
            if oldStyle != newStyle {
                previousBackgroundStyle = oldStyle
                isAnimatingThemeChange = true
                themeChangeProgress = 0
                
                // Animate the blob expansion
                withAnimation(.interpolatingSpring(
                    mass: 1.0,
                    stiffness: 80,
                    damping: 15,
                    initialVelocity: 0
                ).speed(0.8)) {
                    themeChangeProgress = 1.0
                }
                
                // Reset animation state after completion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    isAnimatingThemeChange = false
                    themeChangeProgress = 0
                }
            }
        }
        .onChange(of: colorScheme) { oldColorScheme, newColorScheme in
            globalSettings.updateSystemAppearance(newColorScheme == .dark)
        }
        .onChange(of: yearTrackerSettings.displayColor) { _, _ in
            YearTrackerUtility.saveSettings(yearTrackerSettings)
        }
        .onChange(of: yearTrackerSettings.style) { _, _ in
            YearTrackerUtility.saveSettings(yearTrackerSettings)
        }
        .onChange(of: yearTrackerSettings.showPercentage) { _, _ in
            YearTrackerUtility.saveSettings(yearTrackerSettings)
        }
        .onChange(of: yearTrackerSettings.isUsingDefaultColor) { _, _ in
            YearTrackerUtility.saveSettings(yearTrackerSettings)
        }
        .onAppear {
            // Initialize date and schedule updates
            currentDate = Date()
            NotificationUtility.scheduleNextDayUpdate {
                currentDate = Date()
            }
            
            // Update system appearance
            globalSettings.updateSystemAppearance(colorScheme == .dark)
            
            // Load year tracker settings
            YearTrackerUtility.loadSettings(into: yearTrackerSettings)
            
            // Set up notification observers for year tracker color changes
            YearTrackerUtility.setupColorChangeObserver(for: yearTrackerSettings) {
                YearTrackerUtility.saveSettings(yearTrackerSettings)
            }
            .store(in: &cancellables)
            
            // Set up observers for theme change notifications
            let themeObservers = NotificationUtility.setupThemeChangeObservers(for: globalSettings)
            themeObservers.forEach { $0.store(in: &cancellables) }
        }
        .sheet(isPresented: $navigationState.showingCustomize) {
            if let event = displayedEvents[safe: navigationState.selectedTab] {
                CustomizeView(settings: settings(for: event), eventStore: eventStore)
                    .environmentObject(globalSettings)
                    .onDisappear {
                        // Save year tracker settings when customization is done
                        if event.title == YearTrackerUtility.currentYearTitle {
                            YearTrackerUtility.saveSettings(yearTrackerSettings)
                        }
                    }
            }
        }
        .sheet(isPresented: $navigationState.showingTrackEvent) {
            TrackEventView(eventStore: eventStore, selectedTab: $navigationState.selectedTab)
        }
        .sheet(isPresented: $navigationState.showingSettings) {
            SettingsView()
                .environmentObject(globalSettings)
        }
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
                .environmentObject(globalSettings)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ShowSubscriptionView"))) { _ in
            showSubscriptionView = true
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalSettings())
}
