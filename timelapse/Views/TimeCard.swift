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
    // Helper function to determine cutout image based on color
    private func getCutoutImage(color: Color) -> String {
        // Extract color components for more reliable comparison
        guard let components = color.cgColor?.components, components.count >= 3 else {
            return "blueCut" // Default fallback
        }
        
        // Orange: FF7F00 (approximately R:1.0, G:0.5, B:0.0)
        if components[0] > 0.9 && components[1] > 0.45 && components[1] < 0.55 && components[2] < 0.1 {
            return "orangeCut"
        }
        // Green: 7FBF54 (approximately R:0.5, G:0.75, B:0.33)
        else if components[0] > 0.45 && components[0] < 0.55 && 
                components[1] > 0.7 && components[1] < 0.8 && 
                components[2] > 0.3 && components[2] < 0.4 {
            return "greenCut"
        }
        // Blue or any other color
        else {
            return "blueCut"
        }
    }
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
    @State private var isPressed = false
    @EnvironmentObject var globalSettings: GlobalSettings
    @Binding var selectedTab: Int
    @StateObject private var navigationState = NavigationStateManager.shared
    
    // Add computed properties for dynamic scaling
    private var scaledWidth: CGFloat {
        UIScreen.main.bounds.width * 0.76
    }
    
    private var scaledHeight: CGFloat {
        UIScreen.main.bounds.height * 0.45
    }
    
    var daysSpent: Int {
        totalDays - daysLeft
    }
    
    var percentageLeft: Double {
        (Double(daysLeft) / Double(totalDays)) * 100
    }
    
    var percentageSpent: Double {
        (Double(daysSpent) / Double(totalDays)) * 100
    }
    
    var daysText: String {
        if settings.showPercentage {
            return "left"
        } else if showingDaysLeft {
            // Special cases for days left
            if daysLeft < 0 {
                return "Event Overdue"
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
                    .font(.custom("Inter", size: isGridView ? 8 : 12))
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                
                Spacer()
                
                // Wrap percentage/days display in animation block
                HStack(spacing: 4) {
                    // Only show the number if we're showing percentage or not in special case (today/overdue)
                    if settings.showPercentage || (showingDaysLeft && daysLeft > 0) || !showingDaysLeft {
                        Text(settings.showPercentage 
                            ? String(format: "%.0f%%", percentageLeft) 
                            : String(showingDaysLeft ? daysLeft : daysSpent))
                            .font(.custom("Inter", size: isGridView ? 10 : 12))
                            .contentTransition(.numericText())
                    }
                    
                    Text(daysText)
                        .font(.custom("Inter", size: isGridView ? 10 : 12))
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
                        Image(globalSettings.effectiveBackgroundStyle == .light ? "blackMain" : "whiteMain")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                        
                        // Cutout image based on display color - direct mapping with no default fallback
                        let cutoutImage = getCutoutImage(color: settings.displayColor)
                        Image(cutoutImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    }
                }
            }
        )
        // Add visual feedback when pressed
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3), value: isPressed)
        .onLongPressGesture(minimumDuration: 0.5) {
            // Allow long press for all cards, including year tracker
            HapticFeedback.impact(style: .heavy)
            HapticFeedback.success()
            
            if isYearTracker {
                // For year tracker, go directly to share sheet
                showingShareSheet = true
            } else {
                // For regular events, show action sheet with options
                showingActionSheet = true
            }
        } onPressingChanged: { isPressing in
            // Allow visual feedback for all cards
            if isPressing {
                // Light haptic feedback when touch begins
                HapticFeedback.impact(style: .light)
            }
            isPressed = isPressing
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
                totalDays: totalDays
            )
            .environmentObject(globalSettings)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            // Always show notification settings, removing the pro feature check
            NotificationSettingsView(event: event, eventStore: eventStore)
                .environmentObject(globalSettings)
        }
        .confirmationDialog("Event Options", isPresented: $showingActionSheet, titleVisibility: .visible) {
            // Only show Edit button for non-year tracker events
            if !isYearTracker {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
            
            // Always show notifications option without pro badge
            Button("Notifications") {
                showingNotificationSettings = true
            }
            
            Button("Share") {
                showingShareSheet = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
}
