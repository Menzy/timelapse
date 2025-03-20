import SwiftUI

struct ShareableTimeCard: View {
    let title: String
    let event: Event
    let settings: DisplaySettings
    let eventStore: EventStore
    let daysLeft: Int
    let totalDays: Int
    @State private var showingDaysLeft = true
    @EnvironmentObject var globalSettings: GlobalSettings
    
    // Add computed properties for dynamic scaling
    private var scaledWidth: CGFloat {
        UIScreen.main.bounds.width * 0.8
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
                selectedTab: .constant(0),
                showEventHighlights: false // Always hide event highlights when sharing
            )
        case .triGrid:
            TriGridView(
                daysLeft: daysLeft,
                totalDays: totalDays,
                isYearTracker: isYearTracker,
                startDate: event.creationDate,
                settings: settings,
                eventStore: eventStore,
                selectedTab: .constant(0)
            )
        case .progressBar:
            ProgressBarView(daysLeft: daysLeft, totalDays: totalDays, settings: settings)
                .environmentObject(globalSettings)
        case .countdown:
            CountdownView(
                daysLeft: daysLeft,
                showDaysLeft: showingDaysLeft,
                settings: settings,
                isGridView: false
            )
                .environmentObject(globalSettings)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // The actual card
            VStack(spacing: 0) {
                timeDisplayView()
                    .frame(height: scaledHeight * 0.8)
                    .frame(maxWidth: scaledWidth, alignment: .center)
                    .padding(14)
                
                HStack {
                    Text(title)
                        .font(.custom("Inter", size: 12))
                        .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        // Only show the number if we're showing percentage or not in special case (today/overdue)
                        if settings.showPercentage || (showingDaysLeft && daysLeft > 0) || !showingDaysLeft {
                            Text(settings.showPercentage 
                                ? String(format: "%.0f%%", percentageLeft) 
                                : String(showingDaysLeft ? daysLeft : daysSpent))
                                .font(.custom("Inter", size: 12))
                        }
                        
                        Text(daysText)
                            .font(.custom("Inter", size: 12))
                    }
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 15)
            }
            .background(
                ZStack {
                    Image(globalSettings.effectiveBackgroundStyle == .light ? "blackMain" : "whiteMain")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Cutout image based on display color
                    Image(getCutoutImage(color: settings.displayColor))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            )
            .cornerRadius(16)
            .frame(width: scaledWidth, height: scaledHeight)
            
            // Watermark below the card
            Text(isYearTracker ? "Year Tracker - Created with Timelapse" : "Created with Timelapse")
                .font(.custom("Inter", size: 8))
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .black.opacity(0.7) : .white.opacity(0.7))
        }
    }
}