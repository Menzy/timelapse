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
        } else {
            let count = showingDaysLeft ? daysLeft : daysSpent
            let type = showingDaysLeft ? "left" : "in"
            let dayText = count == 1 ? "day" : "days"
            return "\(dayText) \(type)"
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
            TriGridView(daysLeft: daysLeft, totalDays: totalDays, settings: settings)
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
                    .font(.custom("Inter", size: isGridView ? 8 : 10))
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                
                Spacer()
                
                // Wrap percentage/days display in animation block
                HStack(spacing: 4) {
                    Text(settings.showPercentage 
                         ? String(format: "%.0f%%", percentageLeft) 
                         : String(showingDaysLeft ? daysLeft : daysSpent))
                        .font(.custom("Inter", size: isGridView ? 10 : 12))
                        .contentTransition(.numericText())
                    
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
                        
                        // Cutout image based on display color
                        let cutoutImage = settings.displayColor == Color(hex: "FF7F00") ? "orangeCut" :
                                        settings.displayColor == Color(hex: "7FBF54") ? "greenCut" : 
                                        settings.displayColor == Color(hex: "018AFB") ? "blueCut" : "blueCut"
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
            if globalSettings.areNotificationsAvailable {
                NotificationSettingsView(event: event, eventStore: eventStore)
                    .environmentObject(globalSettings)
            } else {
                // Pro feature notification view
                NavigationView {
                    VStack(spacing: 20) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 50))
                            .foregroundColor(Color(hex: "FF7F00"))
                            .padding(.bottom, 10)
                        
                        Text("Pro Feature")
                            .font(.title2.bold())
                        
                        Text("Notifications are available with a Pro subscription.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingNotificationSettings = false
                            // We need to delay this slightly to avoid presentation conflicts
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                NotificationCenter.default.post(name: NSNotification.Name("ShowSubscriptionView"), object: nil)
                            }
                        }) {
                            Text("Upgrade to Pro")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color(hex: "FF7F00"))
                                .cornerRadius(10)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .navigationTitle("Notification Settings")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Close") {
                                showingNotificationSettings = false
                            }
                        }
                    }
                }
            }
        }
        .confirmationDialog("Event Options", isPresented: $showingActionSheet, titleVisibility: .visible) {
            // Only show Edit button for non-year tracker events
            if !isYearTracker {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
            
            if globalSettings.areNotificationsAvailable {
                Button("Notifications") {
                    showingNotificationSettings = true
                }
            } else {
                Button("Notifications (Pro)") {
                    // Go directly to subscription view
                    NotificationCenter.default.post(name: NSNotification.Name("ShowSubscriptionView"), object: nil)
                }
            }
            
            Button("Share") {
                showingShareSheet = true
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
}
