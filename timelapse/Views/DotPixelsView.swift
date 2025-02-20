import SwiftUI

struct DotPixelsView: View {
    let daysLeft: Int
    let totalDays: Int
    let isYearTracker: Bool
    let startDate: Date
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var selectedDate: Date? = nil
    @State private var tappedIndex: Int? = nil
    
    var daysCompleted: Int {
        totalDays - daysLeft
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        let calendar = Calendar.current
        
        if isYearTracker {
            let today = Date()
            let startOfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: today)))!
            return calendar.date(byAdding: .day, value: index, to: startOfYear)!
        } else {
            // For other events, start from the event's creation date
            return calendar.date(byAdding: .day, value: index, to: calendar.startOfDay(for: startDate))!
        }
    }
    
    private func handleTap(index: Int, date: Date) {
        selectedDate = date
        tappedIndex = index
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if tappedIndex == index {
                tappedIndex = nil
                selectedDate = nil
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, dotSize: CGFloat) {
        let padding: CGFloat = 10
        let availableWidth = size.width - (padding * 2)
        let availableHeight = size.height - (padding * 2)
        
        // For large numbers (>100), use fixed 20 columns
        if totalDays > 100 {
            let columns = 20
            let rows = ceil(Double(totalDays) / Double(columns))
            
            // Calculate dot size based on available width first
            let dotSize = availableWidth / CGFloat(columns)
            
            // Check if dots fit in height
            let requiredHeight = dotSize * CGFloat(rows)
            if requiredHeight <= availableHeight {
                return (columns, dotSize)
            }
            
            // If too tall, recalculate based on height
            return (columns, availableHeight / CGFloat(rows))
        }
        
        // For fewer dots, find optimal layout
        var bestLayout = (columns: 1, dotSize: CGFloat(0))
        var minWastedSpace = CGFloat.infinity
        
        // Try different column counts up to sqrt of totalDays
        for cols in 1...Int(ceil(sqrt(Double(totalDays)))) {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate dot size based on width
            let dotSizeByWidth = availableWidth / CGFloat(cols)
            
            // Calculate required height with this dot size
            let requiredHeight = dotSizeByWidth * CGFloat(rows)
            
            // Calculate wasted space (difference between required and available height)
            let wastedSpace = abs(availableHeight - requiredHeight)
            
            // If this layout wastes less space and fits within height constraints
            if wastedSpace < minWastedSpace && requiredHeight <= availableHeight {
                minWastedSpace = wastedSpace
                bestLayout = (cols, dotSizeByWidth)
            }
        }
        
        return bestLayout
    }
    
    private func getDaysLeftColor() -> Color {
        if globalSettings.effectiveBackgroundStyle == .dream {
            return Color(hex: "002728")
        }
        return globalSettings.effectiveBackgroundStyle == .light ? .white : .black
    }
    
    @ViewBuilder
    func gridItem(index: Int) -> some View {
        let isDaysLeft = index >= (totalDays - daysLeft)
        let date = dateForIndex(index)
        let isSelected = selectedDate == date
        
        Circle()
            .fill(isSelected ? settings.displayColor : (isDaysLeft ?
                  getDaysLeftColor() :
                  settings.displayColor))
            .onTapGesture {
                handleTap(index: index, date: date)
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            VStack(spacing: 0) {
                LazyVGrid(
                    columns: Array(repeating: .init(.fixed(gridParams.dotSize), spacing: 0), 
                                 count: gridParams.columns),
                    spacing: 0
                ) {
                    ForEach(0..<totalDays, id: \.self) { index in
                        gridItem(index: index)
                            .frame(width: gridParams.dotSize, height: gridParams.dotSize)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading) // Changed alignment
                
                Spacer() // Add spacer to push content to top
            }
            .padding(10)
            
            // Overlay for date tooltip
            if let date = selectedDate, let index = tappedIndex {
                let dotPosition = CGPoint(
                    x: CGFloat(index % gridParams.columns) * gridParams.dotSize + gridParams.dotSize/2 + 20,
                    y: CGFloat(index / gridParams.columns) * gridParams.dotSize + gridParams.dotSize/2 + 20
                )
                
                Text(formatDate(date))
                    .font(.inter(12, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.1).opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.2), radius: 2)
                    .position(x: dotPosition.x, y: max(dotPosition.y - 20, 20))
                    .animation(.none, value: selectedDate)
            }
        }
    }
}

