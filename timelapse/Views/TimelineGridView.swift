import SwiftUI

struct TimelineGridView: View {
    @ObservedObject var eventStore: EventStore
    @EnvironmentObject var globalSettings: GlobalSettings
    let yearTrackerSettings: DisplaySettings
    @Binding var selectedTab: Int
    @State private var cardsAppeared: [String: Bool] = [:]
    @State private var initialLayoutComplete = false
    
    // Fixed columns for portrait mode only
    private var gridColumns: [GridItem] {
        let columnCount = DeviceType.isIPad ? DeviceType.gridColumns : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: columnCount)
    }
    
    private var displayedEvents: [Event] {
        let currentYear = Calendar.current.component(.year, from: Date())
        let yearTracker = eventStore.events.first { $0.title == String(currentYear) }
        let otherEvents = eventStore.events.filter { $0.title != String(currentYear) }
        return [yearTracker].compactMap { $0 } + otherEvents
    }
    
    private func settings(for event: Event) -> DisplaySettings {
        let currentYear = Calendar.current.component(.year, from: Date())
        if event.title == String(currentYear) {
            return yearTrackerSettings
        }
        if eventStore.displaySettings[event.id] == nil {
            let newSettings = DisplaySettings(backgroundStyle: globalSettings.effectiveBackgroundStyle)
            eventStore.displaySettings[event.id] = newSettings
        }
        return eventStore.displaySettings[event.id]!
    }
    
    var body: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 16
            let horizontalPadding: CGFloat = DeviceType.isIPad ? 20 : 16
            let bottomNavSpace: CGFloat = DeviceType.isIPad ? 120 : 100 // Account for navigation bar and safe area
            
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: spacing) {
                    ForEach(Array(displayedEvents.enumerated()), id: \.element.id) { index, event in
                        let progress = event.progressDetails()
                        let eventSettings = settings(for: event)
                        let cardId = "\(event.id)-\(eventSettings.showPercentage)"
                        
                        TimeCard(
                            title: event.title,
                            event: event,
                            settings: eventSettings,
                            eventStore: eventStore,
                            daysLeft: progress.daysLeft,
                            totalDays: progress.totalDays,
                            isGridView: true,
                            selectedTab: $selectedTab
                        )
                        .frame(maxWidth: .infinity)
                        .environmentObject(globalSettings)
                        .id(cardId) // Force view update when percentage toggle changes
                        .scaleEffect(cardsAppeared[cardId] == true ? 1.0 : 0.8)
                        .opacity(cardsAppeared[cardId] == true ? 1.0 : 0)
                        // Control animation to prevent layout recalculations during transitions
                        .animation(
                            initialLayoutComplete ? 
                                .spring(
                                    response: 0.5, 
                                    dampingFraction: 0.7
                                )
                                .delay(Double(index) * 0.05) : nil,
                            value: cardsAppeared[cardId]
                        )
                        // Add initial layout control using transaction
                        .transaction { transaction in
                            if !initialLayoutComplete {
                                transaction.animation = nil
                            }
                        }
                        .onAppear {
                            // Don't animate cards until initial layout is complete
                            if !initialLayoutComplete {
                                cardsAppeared[cardId] = false
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, horizontalPadding)
                .padding(.bottom, bottomNavSpace)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.all, edges: .bottom)
            .onAppear {
                // Initialize all cards as not appeared
                for (_, event) in displayedEvents.enumerated() {
                    let eventSettings = settings(for: event)
                    let cardId = "\(event.id)-\(eventSettings.showPercentage)"
                    cardsAppeared[cardId] = false
                }
                
                // Longer delay to allow view to fully layout before animations
                // This ensures DotPixelsView has time to stabilize its layout
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    initialLayoutComplete = true
                    animateCardsAppearance()
                }
            }
        }
    }
    
    private func animateCardsAppearance() {
        // Start animation for all cards with staggered delays
        for (index, event) in displayedEvents.enumerated() {
            let eventSettings = settings(for: event)
            let cardId = "\(event.id)-\(eventSettings.showPercentage)"
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    cardsAppeared[cardId] = true
                }
            }
        }
    }
}
