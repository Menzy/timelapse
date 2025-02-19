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
        let columns = 20 // Match the image layout
        let triangleSize: CGFloat = 12 // Slightly larger triangles
        let spacing: CGFloat = 4 // Spacing between triangles
        
        return (columns, triangleSize, spacing)
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
                    
                    Text(date, style: .date)
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