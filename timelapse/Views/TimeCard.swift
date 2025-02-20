import SwiftUI

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
        
        // Cutout dimensions and position
        let cutoutWidth: CGFloat = width * 0.35
        let cutoutHeight: CGFloat = height * 0.14 // Increased from 0.12 to 0.14
        let cutoutX = width - cutoutWidth - 16 // 16 points from right edge
        let cutoutY = height - cutoutHeight - 16 // 16 points from bottom
        
        // Create cutout shape with rounded corners
        let cutout = UIBezierPath(roundedRect: CGRect(x: cutoutX,
                                                     y: cutoutY,
                                                     width: cutoutWidth,
                                                     height: cutoutHeight),
                                 cornerRadius: 8)
        
        // Convert UIBezierPath to SwiftUI Path
        path.addPath(Path(mainShape.cgPath))
        path.addPath(Path(cutout.cgPath))
        
        return path
    }
}

struct TimeCard: View {
    let title: String
    let event: Event
    @ObservedObject var settings: DisplaySettings
    @ObservedObject var eventStore: EventStore
    let daysLeft: Int
    let totalDays: Int
    @State private var showingDaysLeft = true
    @State private var showingEditSheet = false
    @EnvironmentObject var globalSettings: GlobalSettings // Use global settings
    @State private var isShowingSheet = false // Add this to track sheet presentation

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
        let count = showingDaysLeft ? daysLeft : daysSpent
        let type = showingDaysLeft ? "left" : "in"
        let dayText = count == 1 ? "day" : "days"
        return "\(settings.showPercentage ? "" : "\(dayText) ")\(type)"
    }
    
    @ViewBuilder
    func timeDisplayView() -> some View {
        switch settings.style {
        case .dotPixels:
            DotPixelsView(
                daysLeft: daysLeft,
                totalDays: totalDays,
                isYearTracker: title == String(Calendar.current.component(.year, from: Date())),
                startDate: event.creationDate,
                settings: settings
            )
        case .triGrid:
            TriGridView(daysLeft: daysLeft, totalDays: totalDays, settings: settings)
        case .progressBar:
            ProgressBarView(daysLeft: daysLeft, totalDays: totalDays, settings: settings)
                .environmentObject(globalSettings) // Provide global settings
        case .countdown:
            CountdownView(daysLeft: daysLeft, showDaysLeft: showingDaysLeft, settings: settings)
                .environmentObject(globalSettings) // Provide global settings
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            let paddingSize = geo.size.width * 0.05 // 5% of width as padding
            
            VStack(spacing: 0) {
                // Time display area
                timeDisplayView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom text area
                HStack {
                    Text(title)
                        .font(.inter(10, weight: .medium))
                        .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                    
                    Spacer()
                    
                    // Time display element
                    HStack(spacing: geo.size.width * 0.01) { // 1% of width as spacing
                        Text(settings.showPercentage ? String(format: "%.0f%%", percentageLeft) : "\(daysLeft)")
                            .font(.inter(12, weight: .semibold))
                        Text(settings.showPercentage ? "left" : "Days left")
                            .font(.inter(12, weight: .regular))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, paddingSize * 0.6)
                    .padding(.vertical, paddingSize * 0.3)
                    .background(settings.displayColor)
                    .cornerRadius(paddingSize * 0.4)
                }
            }
            .padding(paddingSize)
            .background(
                CardBackground()
                    .fill(globalSettings.effectiveBackgroundStyle == .light ? .black : .white)
                    .shadow(color: Color.black.opacity(0.1), radius: paddingSize * 0.4, x: 0, y: paddingSize * 0.2)
            )
            .scaleEffect(showingEditSheet ? 0.95 : 1.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.3), value: showingEditSheet)
            .sheet(isPresented: $showingEditSheet) {
                if let event = eventStore.events.first(where: { $0.title == title }) {
                    EditEventView(event: event, eventStore: eventStore)
                }
            }
            .onLongPressGesture {
                if title != String(Calendar.current.component(.year, from: Date())) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showingEditSheet = true
                }
            }
            .onChange(of: showingEditSheet) { _, isShowing in
                isShowingSheet = isShowing
            }
            // Disable gestures when sheet is showing
            .allowsHitTesting(!isShowingSheet)
        }
    }
}
