import SwiftUI

struct TimelineGridView: View {
    @ObservedObject var eventStore: EventStore
    @EnvironmentObject var globalSettings: GlobalSettings
    let yearTrackerSettings: DisplaySettings
    @Binding var selectedTab: Int
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
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
            let horizontalPadding: CGFloat = 16
            let bottomNavSpace: CGFloat = 100 // Account for navigation bar and safe area
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: spacing) {
                    ForEach(displayedEvents) { event in
                        let progress = event.progressDetails()
                        let eventSettings = settings(for: event)
                        
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
                        .id("\(event.id)-\(eventSettings.showPercentage)") // Force view update when percentage toggle changes
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, horizontalPadding)
                .padding(.bottom, bottomNavSpace)
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(.all, edges: .bottom)
            
        }
    }
}
