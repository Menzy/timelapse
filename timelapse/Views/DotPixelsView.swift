import SwiftUI

struct DotPixelsView: View {
    let daysLeft: Int
    let totalDays: Int
    let isYearTracker: Bool
    let startDate: Date
    @ObservedObject var settings: DisplaySettings
    @ObservedObject var eventStore: EventStore
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var selectedDate: Date? = nil
    @State private var tappedIndex: Int? = nil
    // Add binding to control tab selection
    @Binding var selectedTab: Int
    
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
    
    private func isTargetDate(_ date: Date) -> Bool {
        if (!isYearTracker) { return false }
        let calendar = Calendar.current
        return eventStore.events.contains { event in
            guard event.title != String(calendar.component(.year, from: Date())) else { return false }
            return calendar.isDate(date, inSameDayAs: event.targetDate)
        }
    }
    
    private func findEventIndex(for date: Date) -> Int? {
        let calendar = Calendar.current
        let yearString = String(calendar.component(.year, from: Date()))
        return eventStore.events.firstIndex { event in
            guard event.title != yearString,
                  calendar.isDate(date, inSameDayAs: event.targetDate) else { return false }
            return true
        }
    }
    
    private func handleTap(index: Int, date: Date) {
        selectedDate = date
        tappedIndex = index
        
        // If this is a target date, navigate to its event
        if isYearTracker, let eventIndex = findEventIndex(for: date) {
            withAnimation {
                selectedTab = eventIndex
            }
        }
        
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
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, dotSize: CGFloat, spacing: CGFloat) {
        let bottomSpace: CGFloat = 40
        
        // Use full width and calculate available height
        let availableWidth = size.width
        let availableHeight = size.height - bottomSpace
        
        // Calculate optimal number of columns based on aspect ratio
        let aspectRatio = availableWidth / availableHeight
        
        // For large numbers (>100), use dynamic column calculation
        if totalDays > 100 {
            // Base column count on aspect ratio and total items
            let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
            let columns = min(max(baseColumns, 10), 25) // Keep columns between 10 and 25
            let rows = ceil(Double(totalDays) / Double(columns))
            
            // Calculate sizes to fit both width and height
            let widthBasedSize = availableWidth / CGFloat(columns)
            let heightBasedSize = availableHeight / CGFloat(rows)
            
            // Use the smaller size to ensure it fits both dimensions
            let dotSize = min(widthBasedSize, heightBasedSize)
            
            return (columns, dotSize, 0)
        }
        
        // For fewer dots, optimize for both dimensions
        var bestLayout = (columns: 1, dotSize: CGFloat(0), spacing: CGFloat(0))
        var minWastedSpace = CGFloat.infinity
        
        // Calculate maximum columns based on aspect ratio
        let maxColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        
        // Try different column counts
        for cols in 1...maxColumns {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate sizes to fit both width and height
            let widthBasedSize = availableWidth / CGFloat(cols)
            let heightBasedSize = availableHeight / CGFloat(rows)
            
            let dotSize = min(widthBasedSize, heightBasedSize)
            
            // Calculate total used space and wasted space
            let usedWidth = CGFloat(cols) * dotSize
            let usedHeight = CGFloat(rows) * dotSize
            let wastedSpace = abs(availableWidth - usedWidth) + abs(availableHeight - usedHeight)
            
            // If this layout wastes less space and maintains good proportions
            if wastedSpace < minWastedSpace {
                minWastedSpace = wastedSpace
                bestLayout = (cols, dotSize, 0)
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
    func gridItem(index: Int, gridParams: (columns: Int, dotSize: CGFloat, spacing: CGFloat)) -> some View {
        let isDaysLeft = index >= (totalDays - daysLeft)
        let date = dateForIndex(index)
        let isSelected = selectedDate == date
        let isTarget = isTargetDate(date)
        
        ZStack {
            // Main circle fill
            Circle()
                .fill(isSelected ? settings.displayColor : (isDaysLeft ?
                      getDaysLeftColor() :
                      settings.displayColor))
            
            // Add stroke for target dates instead of smaller dot
            if isTarget {
                Circle()
                    .stroke(settings.displayColor, lineWidth: gridParams.dotSize * 0.15)
                    .animation(.smooth, value: isTarget)
            }
        }
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
                        gridItem(index: index, gridParams: gridParams)
                            .frame(width: gridParams.dotSize, height: gridParams.dotSize)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                Spacer()
            }
            // Remove padding to allow dots to touch edges
            
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

