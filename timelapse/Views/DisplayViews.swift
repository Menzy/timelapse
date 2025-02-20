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
    private let segmentCornerRadius: CGFloat = 3
    private let segmentSpacing: CGFloat = 2
    
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
                        .frame(width: segmentWidth, height: segmentHeight)
                }
            }
            .padding(4) // Add padding around segments
            .background(
                RoundedRectangle(cornerRadius: segmentCornerRadius + 4)
                    .stroke(settings.displayColor, lineWidth: 1)
            )
            .padding(.horizontal)
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
        if settings.showPercentage {
            let percentage = (Double(value) / Double(365)) * 100
            return String(format: "%.0f%% left", percentage)
        } else {
            return String(format: "%03d", value)
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Text(displayText)
                .font(.custom("Galgo-Bold", size: geometry.size.width * 3))
                .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .white : .black)
                .minimumScaleFactor(0.3)
                .lineLimit(1)
                .scaleEffect(settings.showPercentage ? 0.8 : 1.0)
                .animation(.easeInOut(duration: 0.3), value: settings.showPercentage)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}
    
