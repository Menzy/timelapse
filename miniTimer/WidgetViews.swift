import SwiftUI
import WidgetKit

struct DotPixelsWidgetView: View {
    let daysLeft: Int
    let totalDays: Int
    let family: WidgetFamily
    @Environment(\.colorScheme) private var colorScheme
    let backgroundTheme: BackgroundChoice
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, dotSize: CGFloat) {
        // For small widgets, use fewer columns to better utilize vertical space
        if family == .systemSmall {
            // Use fewer columns for small widget to make dots more visible
            let columns = 12
            let rows = Int(ceil(Double(totalDays) / Double(columns)))
            
            // Calculate dot size to fill the entire width
            let dotSize = size.width / CGFloat(columns)
            return (columns, dotSize)
        }
        
        // For larger widgets, calculate optimal number of columns based on aspect ratio
        let aspectRatio = size.width / size.height
        let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        let columns = min(max(baseColumns, 10), 30) // Keep columns between 10 and 30
        
        // Calculate rows needed
        let rows = Int(ceil(Double(totalDays) / Double(columns)))
        
        // Calculate dot size to fill the entire width
        let dotSize = size.width / CGFloat(columns)
        
        return (columns, dotSize)
    }
    
    var body: some View {
        let daysSpent = totalDays - daysLeft
        
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            LazyVGrid(
                columns: Array(repeating: .init(.fixed(gridParams.dotSize), spacing: 0), count: gridParams.columns),
                spacing: 0
            ) {
                ForEach(0..<totalDays, id: \.self) { index in
                    Circle()
                        .fill(index < daysSpent ? Color.accentColor : (backgroundTheme == .dark ? Color.white : Color.black))
                        .frame(width: gridParams.dotSize, height: gridParams.dotSize)
                }
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct TriGridWidgetView: View {
    let daysLeft: Int
    let totalDays: Int
    let family: WidgetFamily
    @Environment(\.colorScheme) private var colorScheme
    let backgroundTheme: BackgroundChoice
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, triangleSize: CGFloat) {
        // For small widgets, use fewer columns to better utilize vertical space
        if family == .systemSmall {
            // Use fewer columns for small widget to make triangles more visible
            let columns = 10
            let rows = Int(ceil(Double(totalDays) / Double(columns)))
            
            // Calculate triangle size to fill the entire width
            let triangleSize = size.width / CGFloat(columns)
            return (columns, triangleSize)
        }
        
        // For larger widgets, calculate optimal number of columns based on aspect ratio
        let aspectRatio = size.width / size.height
        let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        let columns = min(max(baseColumns, 8), 25) // Keep columns between 8 and 25
        
        // Calculate rows needed
        let rows = Int(ceil(Double(totalDays) / Double(columns)))
        
        // Calculate triangle size to fill the entire width
        let triangleSize = size.width / CGFloat(columns)
        
        return (columns, triangleSize)
    }
    
    var body: some View {
        let daysSpent = totalDays - daysLeft
        
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            LazyVGrid(
                columns: Array(repeating: .init(.fixed(gridParams.triangleSize), spacing: 0), count: gridParams.columns),
                spacing: 0
            ) {
                ForEach(0..<totalDays, id: \.self) { index in
                    Triangle()
                        .fill(index < daysSpent ? Color.accentColor : (backgroundTheme == .dark ? Color.white : Color.black))
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
    
    private let segmentCount = 25
    private let segmentCornerRadius: CGFloat = 8
    private let segmentSpacing: CGFloat = 2.5
    
    var body: some View {
        let progress = Double(totalDays - daysLeft) / Double(totalDays)
        
        GeometryReader { geometry in
            let segmentHeight = min(geometry.size.height * 0.5, 50)
            
            VStack {
                Spacer()
                HStack(spacing: segmentSpacing) {
                    ForEach(0..<segmentCount, id: \.self) { index in
                        let isActive = Double(index) / Double(segmentCount) < progress
                        RoundedRectangle(cornerRadius: segmentCornerRadius)
                            .fill(isActive ? Color.accentColor : Color.accentColor.opacity(0.2))
                            .frame(height: segmentHeight)
                    }
                }
                .padding(4)
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