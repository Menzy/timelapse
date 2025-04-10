import SwiftUI
import UIKit

// Custom card background shape with cutout
fileprivate struct CardBackground: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let cornerRadius: CGFloat = 16
        
        // Main shape dimensions
        let mainShape = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: width, height: height),
                                    cornerRadius: cornerRadius)
        
        // Convert UIBezierPath to SwiftUI Path
        path.addPath(Path(mainShape.cgPath))
        
        return path
    }
}

// Haptic feedback manager to handle different types of feedback
fileprivate class HapticFeedback {
    static func impact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(.success)
    }
    
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }
}

struct TimeCard: View {
    let title: String
    let event: Event
    @ObservedObject var settings: DisplaySettings
    @ObservedObject var eventStore: EventStore
    let daysLeft: Int
    let totalDays: Int
    let isGridView: Bool
    @State private var showingDaysLeft = true
    @State private var showingEditSheet = false
    @State private var showingShareSheet = false
    @State private var showingActionSheet = false
    @State private var showingNotificationSettings = false
    @State private var showingSubscriptionView = false
    @State private var isPressed = false
    @State private var isLongPressing = false
    @EnvironmentObject var globalSettings: GlobalSettings
    @Binding var selectedTab: Int
    @StateObject private var navigationState = NavigationStateManager.shared
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var showingDeleteConfirmation = false
    
    // Add computed properties for dynamic scaling
    private var scaledWidth: CGFloat {
        DeviceType.timeCardWidth(isLandscape: false)
    }
    
    private var scaledHeight: CGFloat {
        DeviceType.timeCardHeight(isLandscape: false)
    }
    
    var daysSpent: Int {
        totalDays - daysLeft
    }
    
    var percentageLeft: Double {
        // If days left is negative (event has passed), return 0% left
        if daysLeft <= 0 {
            return 0
        }
        return (Double(daysLeft) / Double(totalDays)) * 100
    }
    
    var percentageSpent: Double {
        // Cap at 100% when event has passed its target date
        if daysSpent >= totalDays {
            return 100
        }
        return (Double(daysSpent) / Double(totalDays)) * 100
    }
    
    var daysText: String {
        if settings.showPercentage {
            // Even in percentage mode, handle special messages
            if daysLeft < 0 {
                let daysPassed = abs(daysLeft)
                let dayText = daysPassed == 1 ? "day" : "days"
                return "\(dayText) ago"
            } else if daysLeft == 0 {
                return "It's Today"
            } else {
                return "left"
            }
        } else if showingDaysLeft {
            // Special cases for days left
            if daysLeft < 0 {
                let daysPassed = abs(daysLeft)
                let dayText = daysPassed == 1 ? "day" : "days"
                return "\(dayText) ago"
            } else if daysLeft == 0 {
                return "It's Today"
            } else {
                let dayText = daysLeft == 1 ? "day" : "days"
                return "\(dayText) left"
            }
        } else {
            // Days spent logic remains unchanged
            let dayText = daysSpent == 1 ? "day" : "days"
            return "\(dayText) in"
        }
    }
    
    // Check if this is the year tracker
    private var isYearTracker: Bool {
        return title == String(Calendar.current.component(.year, from: Date()))
    }

    @ViewBuilder
    func timeDisplayView() -> some View {
        switch settings.style {
        case .dotPixels:
            DotPixelsView(
                daysLeft: daysLeft,
                totalDays: totalDays,
                isYearTracker: isYearTracker,
                startDate: event.creationDate,
                settings: settings,
                eventStore: eventStore,
                selectedTab: $selectedTab
            )
        case .triGrid:
            TriGridView(
                daysLeft: daysLeft,
                totalDays: totalDays,
                isYearTracker: isYearTracker,
                startDate: event.creationDate,
                settings: settings,
                eventStore: eventStore,
                selectedTab: $selectedTab
            )
        case .progressBar:
            ProgressBarView(daysLeft: daysLeft, totalDays: totalDays, settings: settings)
                .environmentObject(globalSettings)
        case .countdown:
            CountdownView(
                daysLeft: daysLeft,
                showDaysLeft: showingDaysLeft,
                settings: settings,
                isGridView: isGridView
            )
                .environmentObject(globalSettings)
                .transaction { transaction in
                    if settings.style == .countdown {
                        transaction.animation = nil
                    }
                }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            timeDisplayView()
                .frame(height: isGridView ? scaledHeight * 0.35 : scaledHeight * 0.8)
                .frame(maxWidth: scaledWidth, alignment: .center)
                .padding(isGridView ? 12 : 14) // Use consistent padding for all styles
            
            HStack {
                Text(title)
                    .scaledFont(name: "Inter", size: isGridView ? 10 : 12)
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: isGridView ? nil : (scaledWidth * 0.5), alignment: .leading)
                
                Spacer()
                
                // Wrap percentage/days display in animation block
                HStack(spacing: 4) {
                    // Only show the percentage/number if not at target date or overdue
                    if settings.showPercentage && daysLeft > 0 {
                        Text(String(format: "%.0f%%", percentageLeft))
                            .scaledFont(name: "Inter", size: isGridView ? 10 : 12)
                            .contentTransition(.numericText())
                    } else if settings.showPercentage && daysLeft < 0 {
                        // Show days passed for overdue events in percentage mode
                        Text(String(abs(daysLeft)))
                            .scaledFont(name: "Inter", size: isGridView ? 10 : 12)
                            .contentTransition(.numericText())
                    } else if !settings.showPercentage && ((showingDaysLeft && daysLeft != 0) || !showingDaysLeft) {
                        // Show positive days left, days spent, or days overdue
                        let displayValue = showingDaysLeft ? (daysLeft < 0 ? abs(daysLeft) : daysLeft) : daysSpent
                        Text(String(displayValue))
                            .scaledFont(name: "Inter", size: isGridView ? 10 : 12)
                            .contentTransition(.numericText())
                    }
                    
                    Text(daysText)
                        .scaledFont(name: "Inter", size: isGridView ? 10 : 12)
                }
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                .onTapGesture {
                    withAnimation(.spring()) {
                        showingDaysLeft.toggle()
                    }
                }
            }
            .padding(.horizontal, isGridView ? 12 : 14)
            .padding(.bottom, 15)
        }
        .background(
            Group {
                if isGridView {
                    CardBackground()
                        .fill(globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                } else {
                    ZStack {
                        // Use the new mainShape SVG instead of blackMain/whiteMain images
                        Image("mainShape")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white)
                            .frame(width: scaledWidth, height: scaledHeight)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Use SVG cutout with dynamic color
                        Image("cutoutShape")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(settings.displayColor)
                            .frame(width: scaledWidth, height: scaledHeight)
                    }
                }
            }
        )
        // Improve the scale animation by using an interpolating spring animation with better parameters
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.interpolatingSpring(mass: 1.0, stiffness: 120, damping: 12, initialVelocity: 2), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5, pressing: { isPressing in
            // Update isPressed state with animation
            withAnimation {
                isPressed = isPressing
                // No need for separate isLongPressing state - simplify the logic
            }
            
            if isPressing {
                // Light haptic feedback when touch begins
                HapticFeedback.impact(style: .light)
            }
        }) {
            // Perform when long press is triggered
            HapticFeedback.impact(style: .heavy)
            HapticFeedback.success()
            
            // For both year tracker and regular events, show action sheet with options
            showingActionSheet = true
        }
        // Double tap to expand grid cards to full view
        .onTapGesture(count: 2) {
            if isGridView {
                // Enhanced haptic feedback for a more polished feel
                HapticFeedback.impact(style: .medium)
                HapticFeedback.impact(style: .light)
                
                // Find this event in the eventStore
                if let eventIndex = eventStore.findEventIndex(withId: event.id) {
                    // Use a more sophisticated animation for the transition
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.1)) {
                        // Switch to detailed view
                        globalSettings.showGridLayout = false
                        // Set the tab to this event
                        navigationState.selectedTab = eventIndex
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditEventView(event: event, eventStore: eventStore)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareableCardView(
                title: title,
                event: event,
                settings: settings,
                eventStore: eventStore,
                daysLeft: daysLeft,
                totalDays: totalDays,
                showingDaysLeft: showingDaysLeft
            )
            .environmentObject(globalSettings)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            // Check if user has premium access to notification features
            if paymentManager.isSubscribed {
                NotificationSettingsView(event: event, eventStore: eventStore, isYearTracker: isYearTracker)
                    .environmentObject(globalSettings)
            } else {
                SubscriptionView()
                    .environmentObject(globalSettings)
            }
        }
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
                .environmentObject(globalSettings)
        }
        .confirmationDialog("Event Options", isPresented: $showingActionSheet, titleVisibility: .visible) {
            if isYearTracker {
                // For year tracker, only show Notifications and Share options
                // Show notifications option with premium gate
                Button("Notifications") {
                    if paymentManager.isSubscribed {
                        // Open NotificationSettingsView directly for year tracker
                        showingNotificationSettings = true
                    } else {
                        showingSubscriptionView = true
                    }
                }
                
                Button("Share") {
                    showingShareSheet = true
                }
            } else {
                // For regular events, show Edit, Notifications, Share, and Delete options
                Button("Edit") {
                    showingEditSheet = true
                }
                
                // Show notifications option with premium gate
                Button("Notifications") {
                    if paymentManager.isSubscribed {
                        showingNotificationSettings = true
                    } else {
                        showingSubscriptionView = true
                    }
                }
                
                Button("Share") {
                    showingShareSheet = true
                }
                
                // Add delete option with destructive role
                Button("Delete", role: .destructive) {
                    // Show a confirmation dialog before deleting
                    confirmEventDeletion()
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete '\(title)'? This action cannot be undone.")
        }
    }
    
    private func confirmEventDeletion() {
        // Show the confirmation dialog
        showingDeleteConfirmation = true
    }
    
    private func deleteEvent() {
        // Delete the event from the event store
        eventStore.deleteEvent(withId: event.id)
        
        // Provide haptic feedback to confirm deletion
        HapticFeedback.impact(style: .medium)
    }
}
