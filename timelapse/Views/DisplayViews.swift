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
                .rotationEffect(.degrees(-90))
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
    private let segmentHeight: CGFloat = 45
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
        VStack {
            Spacer()
            HStack(spacing: segmentSpacing) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: segmentCornerRadius)
                        .fill(segmentColor(index: index))
                        .frame(width: nil, height: segmentHeight)
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

struct CountdownView: View {
    let daysLeft: Int
    let showDaysLeft: Bool
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var daysSpent: Int {
        365 - daysLeft
    }
    
    private var displayText: String {
        let value = showDaysLeft ? daysLeft : daysSpent
        // Always show the raw number for the main countdown, regardless of percentage setting
        return String(format: "%03d", value)
    }
    
    var body: some View {
        GeometryReader { geometry in
            Text(displayText)
                .font(.custom("Galgo-Bold", size: geometry.size.width))
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .baselineOffset(-geometry.size.width * 0.1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

