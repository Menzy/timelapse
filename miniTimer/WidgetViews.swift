import SwiftUI
import WidgetKit

struct DotPixelsWidgetView: View {
    let daysLeft: Int
    let totalDays: Int
    let family: WidgetFamily
    @Environment(\.colorScheme) private var colorScheme
    let backgroundTheme: BackgroundChoice
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, dotSize: CGFloat) {
        let availableWidth = size.width
        let availableHeight = size.height - (family == .systemSmall ? 10 : 20)
        let aspectRatio = availableWidth / availableHeight
        
        // For large numbers (>100), use dynamic column calculation
        if totalDays > 100 {
            let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
            let columns = min(max(baseColumns, 4), 25) // Keep columns between 4 and 25
            let rows = Int(ceil(Double(totalDays) / Double(columns)))
            
            let dotSizeByWidth = availableWidth / CGFloat(columns)
            let dotSizeByHeight = availableHeight / CGFloat(rows)
            let dotSize = min(dotSizeByWidth, dotSizeByHeight)
            
            return (columns, dotSize)
        }
        
        // For fewer dots, optimize for both dimensions
        var bestLayout = (columns: 1, dotSize: CGFloat(0))
        var minWastedSpace = CGFloat.infinity
        
        // Calculate maximum columns based on aspect ratio
        let maxColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        
        // Try different column counts
        for cols in 1...maxColumns {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate sizes to fit both width and height
            let dotSizeByWidth = availableWidth / CGFloat(cols)
            let dotSizeByHeight = availableHeight / CGFloat(rows)
            let dotSize = min(dotSizeByWidth, dotSizeByHeight)
            
            // Calculate total used space and wasted space
            let usedWidth = CGFloat(cols) * dotSize
            let usedHeight = CGFloat(rows) * dotSize
            let wastedSpace = abs(availableWidth - usedWidth) + abs(availableHeight - usedHeight)
            
            // If this layout wastes less space
            if wastedSpace < minWastedSpace {
                minWastedSpace = wastedSpace
                bestLayout = (cols, dotSize)
            }
        }
        
        return bestLayout
    }
    
    var body: some View {
        let daysSpent = totalDays - daysLeft
        
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(gridParams.dotSize), spacing: 0), count: gridParams.columns),
                spacing: 0
            ) {
                ForEach(0..<totalDays, id: \.self) { index in
                    Circle()
                        .fill(index < daysSpent ? Color.accentColor : (backgroundTheme == .dark ? Color.white : Color.black))
                        .frame(width: gridParams.dotSize, height: gridParams.dotSize)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(0)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = width * 0.866 // Height for equilateral triangle
        let cornerRadius: CGFloat = width * 0.25 // 25% of width for corner radius
        
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
    let fillColor: Color
    
    var body: some View {
        Triangle()
            .fill(fillColor)
            .clipShape(
                RoundedRectangle(cornerRadius: 3)
            )
    }
}

struct TriGridWidgetView: View {
    let daysLeft: Int
    let totalDays: Int
    let family: WidgetFamily
    @Environment(\.colorScheme) private var colorScheme
    let backgroundTheme: BackgroundChoice
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, triangleSize: CGFloat) {
        let availableWidth = size.width
        let availableHeight = size.height - (family == .systemSmall ? 10 : 20) // Add 10pt spacing for small widget
        let aspectRatio = availableWidth / availableHeight
        
        if family == .systemSmall {
            // Calculate optimal grid based on aspect ratio and total items
            let itemAspectRatio = sqrt(Double(totalDays) * aspectRatio)
            var bestColumns = Int(round(itemAspectRatio))
            var bestRows = Int(ceil(Double(totalDays) / Double(bestColumns)))
            
            // Adjust columns to minimize empty space
            while Double(bestColumns * bestRows) / Double(totalDays) > 1.3 && bestColumns > 1 {
                bestColumns -= 1
                bestRows = Int(ceil(Double(totalDays) / Double(bestColumns)))
            }
            
            // Calculate triangle size considering height ratio for equilateral triangles
            let heightRatio: CGFloat = 0.866 // Height ratio for equilateral triangles
            let spacing: CGFloat = 2.0 // Small spacing for small widget
            let widthBasedSize = (availableWidth - (CGFloat(bestColumns - 1) * spacing)) / CGFloat(bestColumns)
            let heightBasedSize = (availableHeight - (CGFloat(bestRows - 1) * spacing)) / (CGFloat(bestRows) * heightRatio)
            let triangleSize = min(widthBasedSize, heightBasedSize) * 0.95 // Add small margin
            
            return (bestColumns, triangleSize)
        }
        
        // For larger widgets, calculate optimal number of columns based on aspect ratio
        let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        let columns = min(max(baseColumns, 8), 25) // Keep columns between 8 and 25
        
        // Calculate rows needed
        let rows = Int(ceil(Double(totalDays) / Double(columns)))
        
        // Calculate triangle size considering height ratio for equilateral triangles
        let heightRatio: CGFloat = 0.866 // Height ratio for equilateral triangles
        let spacing: CGFloat = 4.0 // Larger spacing for larger widgets
        let widthBasedSize = (size.width - (CGFloat(columns - 1) * spacing)) / CGFloat(columns)
        let heightBasedSize = (size.height - (CGFloat(rows - 1) * spacing)) / (CGFloat(rows) * heightRatio)
        let triangleSize = min(widthBasedSize, heightBasedSize)
        
        return (columns, triangleSize)
    }
    
    var body: some View {
        let daysSpent = totalDays - daysLeft
        
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            LazyVGrid(
                columns: Array(repeating: .init(.fixed(gridParams.triangleSize), spacing: family == .systemSmall ? 2.0 : 4.0), count: gridParams.columns),
                spacing: family == .systemSmall ? 2.0 : 4.0
            ) {
                ForEach(0..<totalDays, id: \.self) { index in
                    RoundedTriangle(fillColor: index < daysSpent ? Color.accentColor : (backgroundTheme == .dark ? Color.white : Color.black))
                        .frame(width: gridParams.triangleSize, height: gridParams.triangleSize)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
    }
}

struct ProgressBarWidgetView: View {
    let daysLeft: Int
    let totalDays: Int
    let family: WidgetFamily
    let backgroundTheme: BackgroundChoice
    
    private let segmentCount = 25
    private let segmentCornerRadius: CGFloat = 8
    private let segmentSpacing: CGFloat = 2.5
    
    private var segmentHeight: CGFloat {
        switch family {
        case .systemMedium:
            return 30 // Reduced height for rectangular widget
        case .systemSmall:
            return 30
        default:
            return 45
        }
    }
    
    var body: some View {
        let progress = Double(totalDays - daysLeft) / Double(totalDays)
        
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack(spacing: segmentSpacing) {
                    ForEach(0..<segmentCount, id: \.self) { index in
                        let isActive = Double(index) / Double(segmentCount) < progress
                        RoundedRectangle(cornerRadius: segmentCornerRadius)
                            .fill(isActive ? 
                                  (backgroundTheme == .dark ? Color.white : Color.black) :
                                  (backgroundTheme == .dark ? Color.white.opacity(0.3) : Color.black.opacity(0.3)))
                            .frame(height: segmentHeight)
                    }
                }
                .padding(4)
                .background(
                    RoundedRectangle(cornerRadius: segmentCornerRadius)
                        .stroke(Color.accentColor, lineWidth: 1)
                )
                .padding(.vertical, 4)
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}

struct CountdownWidgetView: View {
    let daysLeft: Int
    let family: WidgetFamily
    
    var body: some View {
        GeometryReader { geometry in
            Text(String(format: "%03d", daysLeft))
                .font(.system(size: 500, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
                .minimumScaleFactor(0.01)
                .lineLimit(1)
                .frame(width: geometry.size.width * 1.1, height: geometry.size.height * 1.1)
                .position(x: geometry.size.width/2, y: geometry.size.height/2)
                .clipped()
        }
    }
}