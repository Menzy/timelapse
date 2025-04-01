import SwiftUI

struct ShareableTimeCard: View {
    let title: String
    let event: Event
    let settings: DisplaySettings
    let eventStore: EventStore
    let daysLeft: Int
    let totalDays: Int
    let showingDaysLeft: Bool
    @EnvironmentObject var globalSettings: GlobalSettings
    
    // Add computed properties for dynamic scaling
    private var scaledWidth: CGFloat {
        UIScreen.main.bounds.width * 0.76 // Match TimeCard width
    }
    
    private var scaledHeight: CGFloat {
        UIScreen.main.bounds.height * 0.45 // Match TimeCard height
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
                selectedTab: .constant(0),
                showEventHighlights: false
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
        VStack(spacing: 0) {
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
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: scaledWidth * 0.5, alignment: .leading)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        // Only show the percentage/number if not at target date or overdue
                        if settings.showPercentage && daysLeft > 0 {
                            Text(String(format: "%.0f%%", percentageLeft))
                                .font(.custom("Inter", size: 12))
                        } else if settings.showPercentage && daysLeft < 0 {
                            // Show days passed for overdue events in percentage mode
                            Text(String(abs(daysLeft)))
                                .font(.custom("Inter", size: 12))
                        } else if !settings.showPercentage && ((showingDaysLeft && daysLeft != 0) || !showingDaysLeft) {
                            // Show positive days left, days spent, or days overdue
                            let displayValue = showingDaysLeft ? (daysLeft < 0 ? abs(daysLeft) : daysLeft) : daysSpent
                            Text(String(displayValue))
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
                        .aspectRatio(contentMode: .fit)
                        .frame(width: scaledWidth, height: scaledHeight)
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    
                    // Cutout image based on display color
                    Image(getCutoutImage(color: settings.displayColor))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: scaledWidth, height: scaledHeight)
                }
            )
            .cornerRadius(16)
            .frame(width: scaledWidth, height: scaledHeight)
            
            // Watermark below the card
            Text(isYearTracker ? "My Year so Far - Created with Timelapse" : "Created with Timelapse")
                .font(.custom("Inter", size: 8))
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .black.opacity(0.7) : .white.opacity(0.7))
        }
    }
}