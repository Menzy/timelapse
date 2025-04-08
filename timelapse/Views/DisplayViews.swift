import SwiftUI

struct CircleDisplayView: View {
    let daysLeft: Int
    let totalDays: Int
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var daysSpent: Int {
        totalDays - daysLeft
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(settings.displayColor.opacity(0.3), lineWidth: 20)
            
            Circle()
                .trim(from: 0, to: max(0.001, CGFloat(daysSpent) / CGFloat(totalDays)))
                .stroke(settings.displayColor, lineWidth: 20)
                .rotationEffect(.degrees(-126))
                .animation(.linear, value: daysSpent)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ProgressBarView: View {
    let daysLeft: Int
    let totalDays: Int
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    
    private let segmentCount = 25
    private let segmentWidth: CGFloat = 8
    private func calculateSegmentHeight(_ containerHeight: CGFloat) -> CGFloat {
        return containerHeight * (globalSettings.showGridLayout ? 0.16 : 0.18)
    }
    private let segmentCornerRadius: CGFloat = 8
    private let segmentSpacing: CGFloat = 2.5
    
    var daysSpent: Int {
        totalDays - daysLeft
    }
    
    private var progressPercentage: Double {
        Double(daysSpent) / Double(totalDays)
    }
    
    private var filledSegments: Int {
        Int(round(progressPercentage * Double(segmentCount)))
    }
    
    private func segmentColor(index: Int) -> Color {
        let baseColor = globalSettings.effectiveBackgroundStyle == .light ? Color.white : Color.black
        if index < filledSegments {
            return baseColor
        } else {
            return globalSettings.effectiveBackgroundStyle == .light ? Color(hex: "1A1A1A") : Color(hex: "E2E2E2")
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(spacing: segmentSpacing) {
                    ForEach(0..<segmentCount, id: \.self) { index in
                        RoundedRectangle(cornerRadius: segmentCornerRadius)
                            .fill(segmentColor(index: index))
                            .frame(width: nil, height: calculateSegmentHeight(geometry.size.height))
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: segmentCornerRadius)
                        .stroke(settings.displayColor, lineWidth: 1)
                )
                .padding(.vertical, 4)
                Spacer()
            }
        }
    }
}

struct CountdownView: View {
    let daysLeft: Int
    let showDaysLeft: Bool
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    let isGridView: Bool
    
    var daysSpent: Int {
        365 - daysLeft
    }
    
    private var displayText: String {
        // Return "000" when the event is due (today) or overdue
        if daysLeft <= 0 {
            return "000"
        }
        return String(format: "%03d", daysLeft)
    }
    
    // Get appropriate font size for the countdown based on device type
    private func getFontSize() -> CGFloat {
        let baseSize: CGFloat = isGridView ? 3000 : 4000
        
        if DeviceType.isIPad {
            // Adjust size for iPads
            switch DeviceType.current {
            case .iPadSmall:
                return baseSize * 1.2
            case .iPadMedium:
                return baseSize * 1.5
            case .iPadLarge:
                return baseSize * 1.8
            default:
                return baseSize
            }
        } else {
            return baseSize
        }
    }
    
    // Get appropriate minimum scale factor based on device type
    private func getMinScaleFactor() -> CGFloat {
        let baseFactor = isGridView ? 0.06 : 0.1
        
        if DeviceType.isIPad {
            return baseFactor * 0.8 // Smaller scale factor on iPad for clearer text
        } else {
            return baseFactor
        }
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Text(displayText)
                    .font(.custom("Galgo-Bold", size: getFontSize()))
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                    .minimumScaleFactor(getMinScaleFactor())
                    .lineLimit(1)
                    .frame(width: geometry.size.width * (isGridView ? 1.1 : 1.2), 
                           height: geometry.size.height * (isGridView ? 1.1 : 1.2))
                    .position(x: geometry.size.width/2, y: geometry.size.height/2)
                    .clipped()
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

