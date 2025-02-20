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
        let bottomSpace: CGFloat = 80
        
        // Calculate exact available space
        let availableWidth = size.width - (padding * 2)  // 10px on left and right
        let availableHeight = size.height - bottomSpace - padding  // 10px on top
        
        if totalDays > 100 {
            let columns = 20
            let rows = ceil(Double(totalDays) / Double(columns))
            
            // Calculate dot size to exactly fill the available space
            let maxWidthDotSize = availableWidth / CGFloat(columns)
            let maxHeightDotSize = availableHeight / CGFloat(rows)
            
            // Use the smaller of the two sizes to ensure dots fit both horizontally and vertically
            let dotSize = min(maxWidthDotSize, maxHeightDotSize) * 1.2 // Increase dot size by 20%
            
            return (columns, dotSize)
        }
        
        // For fewer dots, optimize to fill the space
        var bestLayout = (columns: 1, dotSize: CGFloat(0))
        var maxDotSize: CGFloat = 0
        
        for cols in 1...Int(ceil(sqrt(Double(totalDays)))) {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate dot size to exactly fill the available space
            let dotSize = min(
                availableWidth / CGFloat(cols),
                availableHeight / CGFloat(rows)
            )
            
            if dotSize > maxDotSize {
                maxDotSize = dotSize
                bestLayout = (cols, dotSize)
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
            
            // Main card container with 10px padding
            VStack(spacing: 0) {
                // Invisible container with equal padding
                VStack(spacing: 0) {
                    // Dot grid at the top
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
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Spacer between grid and text elements
                    Spacer(minLength: 20)
                    
                    // Add some bottom padding for spacing
                    Spacer(minLength: 10)
                }
                .padding(10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
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

