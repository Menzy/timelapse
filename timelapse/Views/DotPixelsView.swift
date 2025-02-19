import SwiftUI

struct DotPixelsView: View {
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if tappedIndex == index {
                tappedIndex = nil
                selectedDate = nil
            }
        }
    }
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, dotSize: CGFloat) {
        let padding: CGFloat = 10 // Exact padding we want
        let bottomSpace: CGFloat = 80 // Space for bottom content
        
        // Calculate exact available space
        let availableWidth = size.width - (padding * 2) // 10px on each side
        let availableHeight = size.height - bottomSpace - (padding * 2) // 10px top and bottom minus label space
        
        // For year view (many dots)
        if totalDays > 100 {
            let columns = 20 // Fixed columns for year view
            let rows = ceil(Double(totalDays) / Double(columns))
            
            // Calculate exact dot size to fit the space
            let dotSize = min(
                availableWidth / CGFloat(columns),
                availableHeight / CGFloat(rows)
            )
            
            return (columns, dotSize)
        }
        
        // For fewer dots, optimize layout
        var bestLayout = (columns: 1, dotSize: CGFloat(0))
        var maxDotSize: CGFloat = 0
        
        // Try different numbers of columns
        for cols in 1...Int(ceil(sqrt(Double(totalDays)))) {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate dot size that would fit exactly in available space
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
            
            ZStack(alignment: .top) {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 10)
                .padding(.top, 10)
                .padding(.bottom, 80)
                
                if let date = selectedDate, let index = tappedIndex {
                    let dotPosition = CGPoint(
                        x: CGFloat(index % gridParams.columns) * gridParams.dotSize + gridParams.dotSize/2 + 10,
                        y: CGFloat(index / gridParams.columns) * gridParams.dotSize + gridParams.dotSize/2 + 10
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
        }
    }
}
