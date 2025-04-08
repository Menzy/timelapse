import SwiftUI

struct RoundedTriangle: View {
    var fillColor: Color
    var isYearTracker: Bool = false
    
    var body: some View {
        Image("Triangle")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(1.0, contentMode: .fit)
            .foregroundColor(fillColor)
            // Use sharper corners for small triangles to improve visibility
            .clipShape(RoundedRectangle(cornerRadius: isYearTracker ? 1.5 : 3))
    }
}

struct TriGridView: View {
    let daysLeft: Int
    let totalDays: Int
    @ObservedObject var settings: DisplaySettings
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var selectedDate: Date? = nil
    @State private var tappedIndex: Int? = nil
    @State private var hoveredIndex: Int? = nil
    @State private var isAnimating = false
    
    // Add these missing parameters to match DotPixelsView
    var isYearTracker: Bool = false
    var startDate: Date = Date()
    var eventStore: EventStore?
    @Binding var selectedTab: Int
    var showEventHighlights: Bool = false
    
    // If the view is created without a binding, use this initializer
    init(daysLeft: Int, totalDays: Int, settings: DisplaySettings) {
        self.daysLeft = daysLeft
        self.totalDays = totalDays
        self.settings = settings
        self._selectedTab = .constant(0)
    }
    
    // Add a complete initializer that matches DotPixelsView functionality
    init(daysLeft: Int, totalDays: Int, isYearTracker: Bool, startDate: Date, settings: DisplaySettings, eventStore: EventStore, selectedTab: Binding<Int>, showEventHighlights: Bool = false) {
        self.daysLeft = daysLeft
        self.totalDays = totalDays
        self.isYearTracker = isYearTracker
        self.startDate = startDate
        self.settings = settings
        self.eventStore = eventStore
        self._selectedTab = selectedTab
        self.showEventHighlights = showEventHighlights
    }
    
    var daysCompleted: Int {
        totalDays - daysLeft
    }
    
    private func dateForIndex(_ index: Int) -> Date {
        let calendar = Calendar.current
        
        if isYearTracker {
            // For year tracker, use start of current year as reference
            let today = Date()
            let startOfYear = calendar.date(from: DateComponents(year: calendar.component(.year, from: today)))!
            return calendar.date(byAdding: .day, value: index, to: startOfYear)!
        } else {
            // For other events, use the event's start date
            return calendar.date(byAdding: .day, value: index, to: calendar.startOfDay(for: startDate))!
        }
    }
    
    private func isTargetDate(_ date: Date) -> Bool {
        // Always return false to disable event highlighting
        return false
    }
    
    private func findEventIndex(for date: Date) -> Int? {
        if (!isYearTracker || eventStore == nil) { return nil }
        let calendar = Calendar.current
        let yearString = String(calendar.component(.year, from: Date()))
        return eventStore!.events.firstIndex { event in
            guard event.title != yearString,
                  calendar.isDate(date, inSameDayAs: event.targetDate) else { return false }
            return true
        }
    }
    
    private func handleTap(index: Int, date: Date) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            selectedDate = date
            tappedIndex = index
        }
        
        // Animate a pulse effect
        withAnimation(.easeInOut(duration: 0.5)) {
            isAnimating = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isAnimating = false
            }
        }
        
        // If this is a target date in year tracker, navigate to its event
        // (Keeping this part for compatibility but it won't trigger due to isTargetDate always returning false)
        if isYearTracker, let eventIndex = findEventIndex(for: date) {
            withAnimation {
                selectedTab = eventIndex
            }
        }
        
        // Reset after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if tappedIndex == index {
                withAnimation(.easeOut) {
                    tappedIndex = nil
                    selectedDate = nil
                }
            }
        }
    }
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, triangleSize: CGFloat, spacing: CGFloat) {
        let bottomSpace: CGFloat = DeviceType.isIPad ? 70 : 60
        let topSpace: CGFloat = DeviceType.isIPad ? 30 : 20 // Add top padding
        
        // Adjust spacing for better visibility based on device type
        let spacing: CGFloat
        
        if DeviceType.isIPad {
            spacing = isYearTracker ? 2 : 4 // Slightly larger spacing for iPad
        } else {
            spacing = isYearTracker ? 1 : 3 // Original spacing for iPhone
        }
        
        // Use full width and calculate available height accounting for both top and bottom padding
        let availableWidth = size.width
        let availableHeight = max(1, size.height - bottomSpace - topSpace) // Ensure positive height
        
        // Calculate optimal number of columns based on aspect ratio
        // Handle edge cases to prevent NaN or infinity
        let aspectRatio = availableWidth > 0 && availableHeight > 0 ? 
            availableWidth / availableHeight : 1.0
        
        // For large numbers (>100), use dynamic column calculation
        if totalDays > 100 {
            // Safely calculate baseColumns
            let baseValue = max(1.0, Double(totalDays) * aspectRatio)
            let baseColumns = Int(ceil(sqrt(baseValue)))
            
            // For year tracker with many days, we want fewer columns to make triangles larger
            var columns: Int
            
            if DeviceType.isIPad {
                // On iPad, we can have more columns for a better visual
                columns = isYearTracker ? 
                    min(max(baseColumns, 10), 25) : // More columns for year tracker on iPad 
                    min(max(baseColumns + 2, 12), 30) // More columns for other events on iPad
            } else {
                // Original values for iPhone
                columns = isYearTracker ? 
                    min(max(baseColumns - 2, 8), 20) : // Fewer columns for year tracker
                    min(max(baseColumns, 10), 25)      // Standard column count for other events
            }
            
            // Ensure we have at least one column
            columns = max(1, columns)
                
            let _ = ceil(Double(totalDays) / Double(columns))
            
            // Calculate triangle size accounting for spacing
            let totalSpacing = spacing * CGFloat(columns - 1)
            
            // Ensure we don't get a negative or zero triangleSize
            let triangleSize = max(1, (availableWidth - totalSpacing) / CGFloat(columns))
            
            return (columns, triangleSize, spacing)
        }
        
        // For fewer triangles, optimize for both dimensions
        var bestLayout = (columns: 1, triangleSize: CGFloat(10), spacing: CGFloat(0)) // Default fallback
        var minWastedSpace = CGFloat.infinity
        
        // Calculate maximum columns based on aspect ratio and device type with safety
        let baseMaxColumns = totalDays > 0 && aspectRatio.isFinite ?
            Int(ceil(sqrt(Double(totalDays) * aspectRatio))) : 1
        
        let maxColumns: Int
        
        if DeviceType.isIPad {
            maxColumns = isYearTracker ? 
                max(1, baseMaxColumns) : // Regular max columns for year tracker
                max(1, baseMaxColumns + 1) // Additional column for other events
        } else {
            maxColumns = isYearTracker ? 
                max(1, baseMaxColumns - 1) : // Reduce max columns for year tracker
                max(1, baseMaxColumns)
        }
        
        // Try different column counts
        for cols in 1...maxColumns {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate triangle size accounting for spacing
            let totalSpacing = spacing * CGFloat(cols - 1)
            let triangleSize = max(1, (availableWidth - totalSpacing) / CGFloat(cols))
            
            // Calculate total used space and wasted space
            let totalVerticalSpacing = spacing * CGFloat(rows - 1)
            let usedHeight = (CGFloat(rows) * triangleSize * 0.866) + totalVerticalSpacing
            
            // Guard against infinite or NaN values
            if usedHeight.isFinite && availableHeight.isFinite {
                let wastedSpace = abs(availableHeight - usedHeight)
                
                // If this layout wastes less vertical space
                if wastedSpace < minWastedSpace {
                    minWastedSpace = wastedSpace
                    bestLayout = (cols, triangleSize, spacing)
                }
            }
        }
        
        return bestLayout
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
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
        let isHovered = hoveredIndex == index
        let isToday = Calendar.current.isDateInToday(date)
        
        ZStack {
            RoundedTriangle(
                fillColor: isSelected ? settings.displayColor : (isDaysLeft ?
                    getDaysLeftColor() :
                    settings.displayColor),
                isYearTracker: isYearTracker
            )
                .aspectRatio(1.0, contentMode: .fill)
                .scaleEffect(isSelected ? 1.15 : (isHovered ? 1.08 : 1.0))
                .shadow(color: isSelected || isHovered ? settings.displayColor.opacity(0.5) : .clear, 
                        radius: isSelected ? 4 : (isHovered ? 2 : 0))
                .rotationEffect(isAnimating && isSelected ? .degrees(10) : .degrees(0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
            
            // Simple highlight for today's date
            if isToday {
                RoundedTriangle(
                    fillColor: settings.displayColor,
                    isYearTracker: isYearTracker
                )
                    .aspectRatio(1.0, contentMode: .fill)
                    .opacity(0.3)
            }
        }
        .onTapGesture {
            handleTap(index: index, date: date)
        }
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                hoveredIndex = isHovering ? index : nil
            }
        }
        .contentShape(Rectangle()) // Improve tap target
    }
    
    var body: some View {
        GeometryReader { geometry in
            let gridParams = calculateGridParameters(for: geometry.size)
            
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    LazyVGrid(
                        columns: Array(
                            repeating: .init(
                                .fixed(gridParams.triangleSize), 
                                spacing: gridParams.spacing
                            ), 
                            count: gridParams.columns
                        ), 
                        spacing: gridParams.spacing
                    ) {
                        ForEach(0..<totalDays, id: \.self) { index in
                            gridItem(index: index)
                                .frame(width: gridParams.triangleSize, height: gridParams.triangleSize)
                                // Add a very slight padding to ensure triangles don't clip 
                                .padding(isYearTracker ? 0.1 : 0.2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer(minLength: 0)
                }
                
                if let date = selectedDate, let index = tappedIndex {
                    let row = index / gridParams.columns
                    let col = index % gridParams.columns
                    
                    // Calculate triangle position
                    let triangleX = CGFloat(col) * (gridParams.triangleSize + gridParams.spacing) + gridParams.triangleSize/2
                    let triangleY = CGFloat(row) * (gridParams.triangleSize + gridParams.spacing) + gridParams.triangleSize/2
                    
                    // Always position the tooltip above the triangle with proper spacing
                    // Use a minimum offset from the top of the view to ensure visibility
                    let tooltipOffset = triangleY < 40 ? max(10, triangleY - 10) : triangleY - 30
                    
                    Text(formatDate(date))
                        .font(.inter(12, weight: .medium))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(globalSettings.effectiveBackgroundStyle == .light ? 
                            Color(white: 0.1) : 
                            Color.white)
                        .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? 
                            .white : 
                            .black)
                        .cornerRadius(6)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        .position(x: triangleX, y: tooltipOffset)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}