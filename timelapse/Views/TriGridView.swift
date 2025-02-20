import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = width * 0.866 // Height for equilateral triangle
        
        path.move(to: CGPoint(x: width/2, y: 0))
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
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
        let padding: CGFloat = 10
        let bottomSpace: CGFloat = 80
        
        // Calculate exact available space
        let availableWidth = size.width - (padding * 2)
        let availableHeight = size.height - bottomSpace - padding
        
        if totalDays > 100 {
            let columns = 20
            let rows = ceil(Double(totalDays) / Double(columns))
            
            // Calculate triangle size to fill the available space
            let maxWidthTriSize = availableWidth / CGFloat(columns)
            let maxHeightTriSize = availableHeight / CGFloat(rows)
            
            // Use the smaller of the two sizes to ensure triangles fit both horizontally and vertically
            let triangleSize = min(maxWidthTriSize, maxHeightTriSize) * 1.1 // 95% to account for minimal spacing
            let spacing = triangleSize * 0.05 // 5% of triangle size for spacing
            
            return (columns, triangleSize, spacing)
        }
        
        // For fewer triangles, optimize to fill the space
        var bestLayout = (columns: 1, triangleSize: CGFloat(0), spacing: CGFloat(0))
        var maxTriangleSize: CGFloat = 0
        
        for cols in 1...Int(ceil(sqrt(Double(totalDays)))) {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate triangle size to fill the available space
            let potentialTriSize = min(
                availableWidth / CGFloat(cols),
                availableHeight / CGFloat(rows)
            )
            
            if potentialTriSize > maxTriangleSize {
                maxTriangleSize = potentialTriSize
                let spacing = potentialTriSize * 0.05 // 5% of triangle size for spacing
                bestLayout = (cols, potentialTriSize * 0.95, spacing) // 95% of space for triangle
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
            
            ZStack(alignment: .top) {
                LazyVGrid(columns: Array(repeating: .init(.fixed(gridParams.triangleSize), spacing: gridParams.spacing), count: gridParams.columns), spacing: gridParams.spacing * 0.5) {
                    ForEach(0..<totalDays, id: \.self) { index in
                        gridItem(index: index)
                            .frame(width: gridParams.triangleSize, height: gridParams.triangleSize)
                    }
                }
                .frame(width: CGFloat(gridParams.columns) * (gridParams.triangleSize + gridParams.spacing))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                
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