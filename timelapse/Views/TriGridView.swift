import SwiftUI

struct RoundedTriangle: View {
    var fillColor: Color
    
    var body: some View {
        Image("Triangle")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .foregroundColor(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

struct TriGridView: View {
    let daysLeft: Int
    let totalDays: Int
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var selectedDate: Date? = nil
    @State private var tappedIndex: Int? = nil
    
    var daysCompleted: Int {
        totalDays - daysLeft
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let startOfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: today)))!
        return calendar.date(byAdding: .day, value: index, to: startOfYear)!
    }
    
    private func handleTap(index: Int, date: Date) {
        selectedDate = date
        tappedIndex = index
        
        // Reset after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if tappedIndex == index {
                tappedIndex = nil
                selectedDate = nil
            }
        }
    }
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, triangleSize: CGFloat, spacing: CGFloat) {
        let bottomSpace: CGFloat = 60
        let topSpace: CGFloat = 20 // Add top padding
        let spacing: CGFloat = 4 // Add spacing between triangles
        
        // Use full width and calculate available height accounting for both top and bottom padding
        let availableWidth = size.width
        let availableHeight = size.height - bottomSpace - topSpace
        
        // Calculate optimal number of columns based on aspect ratio
        let aspectRatio = availableWidth / availableHeight
        
        // For large numbers (>100), use dynamic column calculation
        if totalDays > 100 {
            // Base column count on aspect ratio and total items
            let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
            let columns = min(max(baseColumns, 10), 25) // Keep columns between 10 and 25
            let _ = ceil(Double(totalDays) / Double(columns))
            
            // Calculate triangle size accounting for spacing
            let totalSpacing = spacing * CGFloat(columns - 1)
            let triangleSize = (availableWidth - totalSpacing) / CGFloat(columns)
            
            return (columns, triangleSize, spacing)
        }
        
        // For fewer triangles, optimize for both dimensions
        var bestLayout = (columns: 1, triangleSize: CGFloat(0), spacing: CGFloat(0))
        var minWastedSpace = CGFloat.infinity
        
        // Calculate maximum columns based on aspect ratio
        let maxColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        
        // Try different column counts
        for cols in 1...maxColumns {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate triangle size accounting for spacing
            let totalSpacing = spacing * CGFloat(cols - 1)
            let triangleSize = (availableWidth - totalSpacing) / CGFloat(cols)
            
            // Calculate total used space and wasted space
            let totalVerticalSpacing = spacing * CGFloat(rows - 1)
            let usedHeight = (CGFloat(rows) * triangleSize * 0.866) + totalVerticalSpacing
            let wastedSpace = abs(availableHeight - usedHeight)
            
            // If this layout wastes less vertical space
            if wastedSpace < minWastedSpace {
                minWastedSpace = wastedSpace
                bestLayout = (cols, triangleSize, spacing)
            }
        }
        
        return bestLayout
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d, yyyy"
        return formatter.string(from: date)
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
        
        RoundedTriangle(fillColor: isSelected ? settings.displayColor : (isDaysLeft ?
                getDaysLeftColor() :
                settings.displayColor))
            .aspectRatio(1.0, contentMode: .fill)
            .onTapGesture {
                handleTap(index: index, date: date)
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    LazyVGrid(columns: Array(repeating: .init(.fixed(gridParams.triangleSize), spacing: gridParams.spacing), count: gridParams.columns), spacing: gridParams.spacing) {
                        ForEach(0..<totalDays, id: \.self) { index in
                            gridItem(index: index)
                                .frame(width: gridParams.triangleSize, height: gridParams.triangleSize)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 0)
                }
                
                if let date = selectedDate, let index = tappedIndex {
                    let dotPosition = CGPoint(
                        x: CGFloat(index % gridParams.columns) * (gridParams.triangleSize + gridParams.spacing) + gridParams.triangleSize/2,
                        y: CGFloat(index / gridParams.columns) * (gridParams.triangleSize + gridParams.spacing) + gridParams.triangleSize/2
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
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}