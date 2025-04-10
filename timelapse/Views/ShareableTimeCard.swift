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
    
    // Update computed properties to use DeviceTypeHelper for proper iPad scaling
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
            // Days spent logic
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
                        .scaledFont(name: "Inter", size: 12)
                        .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: scaledWidth * 0.5, alignment: .leading)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        // Only show the percentage/number if not at target date or overdue
                        if settings.showPercentage && daysLeft > 0 {
                            Text(String(format: "%.0f%%", percentageLeft))
                                .scaledFont(name: "Inter", size: 12)
                        } else if settings.showPercentage && daysLeft < 0 {
                            // Show days passed for overdue events in percentage mode
                            Text(String(abs(daysLeft)))
                                .scaledFont(name: "Inter", size: 12)
                        } else if !settings.showPercentage && ((showingDaysLeft && daysLeft != 0) || !showingDaysLeft) {
                            // Show positive days left, days spent, or days overdue
                            let displayValue = showingDaysLeft ? (daysLeft < 0 ? abs(daysLeft) : daysLeft) : daysSpent
                            Text(String(displayValue))
                                .scaledFont(name: "Inter", size: 12)
                        }
                        
                        Text(daysText)
                            .scaledFont(name: "Inter", size: 12)
                    }
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 15)
            }
            .background(
                ZStack {
                    // Use the mainShape SVG instead of blackMain/whiteMain images
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
            )
            .cornerRadius(16)
            .frame(width: scaledWidth, height: scaledHeight)
            
            // Watermark below the card
            Text(isYearTracker ? "My Year so Far - Created with Timelapse" : "Created with Timelapse")
                .scaledFont(name: "Inter", size: 8)
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .black.opacity(0.7) : .white.opacity(0.7))
        }
    }
}