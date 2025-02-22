import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = width * 0.866 // Height for equilateral triangle
        let cornerRadius: CGFloat = width * 0.25 // Now cornerRadius is 15% of width
        
        // Calculate points
        let top = CGPoint(x: width/2, y: 0)
        let bottomRight = CGPoint(x: width, y: height)
        let bottomLeft = CGPoint(x: 0, y: height)
        
        // Calculate vectors for corner rounding
        let topToRight = CGPoint(x: bottomRight.x - top.x, y: bottomRight.y - top.y)
        let rightToLeft = CGPoint(x: bottomLeft.x - bottomRight.x, y: bottomLeft.y - bottomRight.y)
        let leftToTop = CGPoint(x: top.x - bottomLeft.x, y: top.y - bottomLeft.y)
        
        // Normalize vectors
        let topToRightLength = sqrt(topToRight.x * topToRight.x + topToRight.y * topToRight.y)
        let rightToLeftLength = sqrt(rightToLeft.x * rightToLeft.x + rightToLeft.y * rightToLeft.y)
        let leftToTopLength = sqrt(leftToTop.x * leftToTop.x + leftToTop.y * leftToTop.y)
        
        // Calculate corner points
        let topCornerStart = CGPoint(
            x: top.x + (topToRight.x / topToRightLength) * cornerRadius,
            y: top.y + (topToRight.y / topToRightLength) * cornerRadius
        )
        let topCornerEnd = CGPoint(
            x: top.x - (leftToTop.x / leftToTopLength) * cornerRadius,
            y: top.y - (leftToTop.y / leftToTopLength) * cornerRadius
        )
        
        let rightCornerStart = CGPoint(
            x: bottomRight.x - (topToRight.x / topToRightLength) * cornerRadius,
            y: bottomRight.y - (topToRight.y / topToRightLength) * cornerRadius
        )
        let rightCornerEnd = CGPoint(
            x: bottomRight.x + (rightToLeft.x / rightToLeftLength) * cornerRadius,
            y: bottomRight.y + (rightToLeft.y / rightToLeftLength) * cornerRadius
        )
        
        let leftCornerStart = CGPoint(
            x: bottomLeft.x - (rightToLeft.x / rightToLeftLength) * cornerRadius,
            y: bottomLeft.y - (rightToLeft.y / rightToLeftLength) * cornerRadius
        )
        let leftCornerEnd = CGPoint(
            x: bottomLeft.x + (leftToTop.x / leftToTopLength) * cornerRadius,
            y: bottomLeft.y + (leftToTop.y / leftToTopLength) * cornerRadius
        )
        
        // Draw the path
        path.move(to: topCornerStart)
        path.addLine(to: rightCornerStart)
        path.addQuadCurve(to: rightCornerEnd, control: bottomRight)
        path.addLine(to: leftCornerStart)
        path.addQuadCurve(to: leftCornerEnd, control: bottomLeft)
        path.addLine(to: topCornerEnd)
        path.addQuadCurve(to: topCornerStart, control: top)
        
        return path
    }
}

struct RoundedTriangle: View {
    var body: some View {
        Triangle()
            .clipShape(
                RoundedRectangle(cornerRadius: 3)
            )
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
            let heightBasedSize = availableHeight / (CGFloat(rows) * 0.866)
            
            // Use the smaller size to ensure it fits both dimensions
            let triangleSize = min(widthBasedSize, heightBasedSize)
            
            return (columns, triangleSize, 0)
        }
        
        // For fewer triangles, optimize for both dimensions
        var bestLayout = (columns: 1, triangleSize: CGFloat(0), spacing: CGFloat(0))
        var minWastedSpace = CGFloat.infinity
        
        // Calculate maximum columns based on aspect ratio
        let maxColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        
        // Try different column counts
        for cols in 1...maxColumns {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate sizes to fit both width and height
            let widthBasedSize = availableWidth / CGFloat(cols)
            let heightBasedSize = availableHeight / (CGFloat(rows) * 0.866)
            
            let triangleSize = min(widthBasedSize, heightBasedSize)
            
            // Calculate total used space and wasted space
            let usedWidth = CGFloat(cols) * triangleSize
            let usedHeight = CGFloat(rows) * triangleSize * 0.866
            let wastedSpace = abs(availableWidth - usedWidth) + abs(availableHeight - usedHeight)
            
            // If this layout wastes less space and maintains good proportions
            if wastedSpace < minWastedSpace {
                minWastedSpace = wastedSpace
                bestLayout = (cols, triangleSize, 0)
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
        
        RoundedTriangle()
            .foregroundColor(isSelected ? settings.displayColor : (isDaysLeft ?
                getDaysLeftColor() :
                settings.displayColor))
            .aspectRatio(1.15, contentMode: .fit)
            .onTapGesture {
                handleTap(index: index, date: date)
            }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    LazyVGrid(columns: Array(repeating: .init(.fixed(gridParams.triangleSize), spacing: 0), count: gridParams.columns), spacing: 0) {
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