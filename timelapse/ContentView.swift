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
    
    @State private var showSubscriptionExpiredAlert = false
    @State private var hiddenEventsCount = 0
    @State private var viewRefreshTrigger = false
    
    private var displayedEvents: [Event] {
        // Using viewRefreshTrigger here will cause this property to be recalculated when it changes
        _ = viewRefreshTrigger
        
        // Get events limited by subscription status
        let limitedEvents = eventStore.getEventsLimitedBySubscription()
        
        // Always put year tracker first, then other events
        let yearTracker = limitedEvents.first { $0.title == YearTrackerUtility.currentYearTitle }
        let otherEvents = limitedEvents.filter { $0.title != YearTrackerUtility.currentYearTitle }
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
                                insertion: AnyTransition.opacity
                                    .combined(with: .scale(scale: 0.98))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.7)),
                                removal: AnyTransition.opacity
                                    .combined(with: .scale(scale: 0.95))
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8))
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
                                    .frame(width: DeviceType.timeCardWidth())
                                    .offset(y: DeviceType.isIPad ? -60 : -40)
                                    .tag(index)
                                    .environmentObject(globalSettings)
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .trailing)
                                                .combined(with: .opacity)
                                                .animation(.spring(response: 0.4, dampingFraction: 0.8)),
                                            removal: .move(edge: .leading)
                                                .combined(with: .opacity)
                                                .animation(.spring(response: 0.4, dampingFraction: 0.8))
                                        )
                                    )
                                }
                            }
                            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                        }
                        .onAppear {
                            // Reset the setting but don't automatically trigger subscription view on app start
                            DispatchQueue.main.async {
                                globalSettings.showGridLayout = false
                                // Don't show subscription view automatically
                                // showSubscriptionView = true
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
                            .frame(width: DeviceType.timeCardWidth())
                            .offset(y: DeviceType.isIPad ? -60 : -40)
                            .tag(index)
                            .environmentObject(globalSettings)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8)),
                                    removal: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .animation(.spring(response: 0.5, dampingFraction: 0.8))
                                )
                            )
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .transition(
                    .asymmetric(
                        insertion: AnyTransition.opacity
                            .combined(with: .scale(scale: 1.02))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8)),
                        removal: AnyTransition.opacity
                            .combined(with: .scale(scale: 0.98))
                            .animation(.spring(response: 0.5, dampingFraction: 0.7))
                    )
                )
                .onChange(of: navigationState.selectedTab) { oldValue, newValue in
                    withAnimation {
                        navigationState.selectedTab = min(max(newValue, 0), displayedEvents.count - 1)
                    }
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: globalSettings.showGridLayout)
    }
    
    var body: some View {
        ZStack {
            // Background with transition animation
            BackgroundView(
                isAnimating: isAnimatingThemeChange,
                previousStyle: previousBackgroundStyle,
                progress: themeChangeProgress
            )
            .environmentObject(globalSettings)
            
            ZStack(alignment: .bottom) {
                // Main content
                timelineContent
                
                // Navigation with page indicators
                NavigationContentView(
                    selectedTab: navigationState.selectedTab,
                    eventCount: displayedEvents.count
                )
                .environmentObject(globalSettings)
                
                // Only show one banner at a time - prioritize trial period banner
                if PaymentManager.isInTrialPeriod(), let daysLeft = PaymentManager.getDaysLeftInTrial() {
                    // Show trial period banner for all users in trial period
                    // (whether they have a subscription or not)
                    VStack {
                        Spacer()
                        Button(action: {
                            showSubscriptionView = true
                        }) {
                            HStack(spacing: 6) {
                                Text("Trial ends in \(daysLeft) \(daysLeft == 1 ? "day" : "days")")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Upgrade")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(15)
                            .padding(.bottom, 6)
                        }
                    }
                } else if !paymentManager.isSubscribed && eventStore.events.count > eventStore.getEventsLimitedBySubscription().count {
                    // Show events hidden banner only if not in trial period
                    VStack {
                        Spacer()
                        Button(action: {
                            showSubscriptionView = true
                        }) {
                            HStack(spacing: 6) {
                                Text("\(eventStore.events.count - eventStore.getEventsLimitedBySubscription().count) \(eventStore.events.count - eventStore.getEventsLimitedBySubscription().count == 1 ? "event" : "events") hidden")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                
                                Text("Upgrade")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow)
                                    .foregroundColor(.black)
                                    .cornerRadius(4)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(15)
                            .padding(.bottom, 6)
                        }
                    }
                }
            }
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
            
            // Check subscription and trial status on app launch
            Task {
                await paymentManager.updateSubscriptionStatus()
            }
            
            // Set up a timer to periodically refresh trial status display
            let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
            
            // Store the cancellable so we can clean it up later
            timer.sink { _ in
                // This will trigger a refresh of the UI to update the days left in trial
                viewRefreshTrigger.toggle()
            }.store(in: &cancellables)
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
            // Only show subscription view if user is not already subscribed
            if !paymentManager.isSubscribed && !paymentManager.hasLifetimePurchase {
                showSubscriptionView = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionStatusChanged"))) { _ in
            // Force refresh the view to update displayed events based on subscription status
            // This ensures that if a user's subscription expires, excess events are hidden
            viewRefreshTrigger.toggle()
            
            // Check if subscription was lost and there are hidden events
            if !paymentManager.isSubscribed {
                let hiddenCount = eventStore.events.count - eventStore.getEventsLimitedBySubscription().count
                if hiddenCount > 0 {
                    hiddenEventsCount = hiddenCount
                    showSubscriptionExpiredAlert = true
                }
            }
        }
        .alert("Subscription Expired", isPresented: $showSubscriptionExpiredAlert) {
            Button("Subscribe", role: .none) {
                showSubscriptionView = true
            }
            Button("OK", role: .cancel) { }
        } message: {
            Text("Your subscription has expired. \(hiddenEventsCount) \(hiddenEventsCount == 1 ? "event is" : "events are") now hidden. Upgrade to TimeLapse Pro to regain access to all your events.")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(GlobalSettings())
}
