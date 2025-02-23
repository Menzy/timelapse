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
    let isGridView: Bool
    @State private var showingDaysLeft = true
    @State private var showingEditSheet = false
    @EnvironmentObject var globalSettings: GlobalSettings // Use global settings

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
                .transaction { transaction in
                    // Disable animations for the countdown view
                    if settings.style == .countdown {
                        transaction.animation = nil
                    }
                }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            timeDisplayView()
                .frame(height: isGridView ? 150 : 300)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(isGridView ? 12 : 24)
            
            HStack {
                Text(title)
                    .font(.inter(isGridView ? 8 : 10, weight: .medium))
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                
                Spacer()
                
                // Wrap percentage/days display in animation block
                HStack(spacing: 4) {
                    Text(settings.showPercentage 
                         ? String(format: "%.0f%%", percentageLeft) 
                         : String(daysLeft))
                        .font(.inter(isGridView ? 10 : 12, weight: .semibold))
                        .contentTransition(.numericText())
                    
                    Text(daysText)
                        .font(.inter(isGridView ? 10 : 12, weight: .regular))
                }
                .animation(.smooth, value: settings.showPercentage)
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
            }
            .padding(.horizontal, isGridView ? 12 : 24)
            .padding(.bottom, isGridView ? 12 : 24)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(globalSettings.effectiveBackgroundStyle == .light ? .black : .white)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                // Cutout shape with display color
                if !isGridView {
                    GeometryReader { geometry in
                        let cutoutWidth = geometry.size.width * 0.35
                        let cutoutHeight = geometry.size.height * 0.14
                        let cutoutX = geometry.size.width - cutoutWidth - 16
                        let cutoutY = geometry.size.height - cutoutHeight - 16
                        
                        RoundedRectangle(cornerRadius: 8)
                            .fill(settings.displayColor)
                            .frame(width: cutoutWidth, height: cutoutHeight)
                            .position(x: cutoutX + cutoutWidth/2, y: cutoutY + cutoutHeight/2)
                    }
                }
            }
        )
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
    }
}
