import SwiftUI
import UIKit

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
    @State private var hoveredIndex: Int? = nil
    @State private var isAnimating = false
    // Add binding to control tab selection
    @Binding var selectedTab: Int
    // Add parameter to control whether to show event highlights
    var showEventHighlights: Bool = true
    
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
        if (!isYearTracker || !showEventHighlights) { return false }
        let calendar = Calendar.current
        return eventStore.events.contains { event in
            guard event.title != String(calendar.component(.year, from: Date())) else { return false }
            return calendar.isDate(date, inSameDayAs: event.targetDate)
        }
    }
    
    private func findEventIndex(for date: Date) -> Int? {
        if (!showEventHighlights) { return nil }
        let calendar = Calendar.current
        let yearString = String(calendar.component(.year, from: Date()))
        return eventStore.events.firstIndex { event in
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
        
        // If this is a target date, navigate to its event
        if isYearTracker, let eventIndex = findEventIndex(for: date) {
            withAnimation {
                selectedTab = eventIndex
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if tappedIndex == index {
                withAnimation(.easeOut) {
                    tappedIndex = nil
                    selectedDate = nil
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    private func calculateGridParameters(for size: CGSize) -> (columns: Int, dotSize: CGFloat, spacing: CGFloat) {
        let bottomSpace: CGFloat = DeviceType.isIPad ? 50 : 40
        
        // Use full width and calculate available height
        let availableWidth = size.width
        let availableHeight = size.height - bottomSpace
        
        // Calculate optimal number of columns based on aspect ratio
        let aspectRatio = availableWidth / availableHeight
        
        // Determine spacing based on device type
        let spacing: CGFloat = DeviceType.isIPad ? 2 : 0 // Add small spacing on iPad for better visibility
        
        // For large numbers (>100), use dynamic column calculation
        if totalDays > 100 {
            // Base column count on aspect ratio and total items
            let baseColumns = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
            
            // Adjust columns based on device type
            let columns: Int
            if DeviceType.isIPad {
                columns = min(max(baseColumns + 2, 12), 30) // More columns on iPad
            } else {
                columns = min(max(baseColumns, 10), 25) // Original columns for iPhone
            }
            
            let rows = ceil(Double(totalDays) / Double(columns))
            
            // Calculate sizes to fit both width and height, accounting for spacing
            let totalHorizontalSpacing = spacing * CGFloat(columns - 1)
            let totalVerticalSpacing = spacing * CGFloat(rows - 1)
            
            let widthBasedSize = (availableWidth - totalHorizontalSpacing) / CGFloat(columns)
            let heightBasedSize = (availableHeight - totalVerticalSpacing) / CGFloat(rows)
            
            // Use the smaller size to ensure it fits both dimensions
            let dotSize = min(widthBasedSize, heightBasedSize)
            
            return (columns, dotSize, spacing)
        }
        
        // For fewer dots, optimize for both dimensions
        var bestLayout = (columns: 1, dotSize: CGFloat(0), spacing: CGFloat(0))
        var minWastedSpace = CGFloat.infinity
        
        // Calculate maximum columns based on aspect ratio
        let maxColumnsBase = Int(ceil(sqrt(Double(totalDays) * aspectRatio)))
        let maxColumns = DeviceType.isIPad ? maxColumnsBase + 1 : maxColumnsBase
        
        // Try different column counts
        for cols in 1...maxColumns {
            let rows = Int(ceil(Double(totalDays) / Double(cols)))
            
            // Calculate sizes to fit both width and height, accounting for spacing
            let totalHorizontalSpacing = spacing * CGFloat(cols - 1)
            let totalVerticalSpacing = spacing * CGFloat(rows - 1)
            
            let widthBasedSize = (availableWidth - totalHorizontalSpacing) / CGFloat(cols)
            let heightBasedSize = (availableHeight - totalVerticalSpacing) / CGFloat(rows)
            
            let dotSize = min(widthBasedSize, heightBasedSize)
            
            // Calculate total used space and wasted space
            let usedWidth = (CGFloat(cols) * dotSize) + totalHorizontalSpacing
            let usedHeight = (CGFloat(rows) * dotSize) + totalVerticalSpacing
            let wastedSpace = abs(availableWidth - usedWidth) + abs(availableHeight - usedHeight)
            
            // If this layout wastes less space and maintains good proportions
            if wastedSpace < minWastedSpace {
                minWastedSpace = wastedSpace
                bestLayout = (cols, dotSize, spacing)
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
        let isHovered = hoveredIndex == index
        
        ZStack {
            // Main circle fill
            Circle()
                .fill(isSelected ? settings.displayColor : (isDaysLeft ?
                      getDaysLeftColor() :
                      settings.displayColor))
                .scaleEffect(isSelected ? 1.15 : (isHovered ? 1.08 : 1.0))
                .shadow(color: isSelected || isHovered ? settings.displayColor.opacity(0.5) : .clear, 
                        radius: isSelected ? 4 : (isHovered ? 2 : 0))
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
                .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isHovered)
            
            // Add stroke for target dates instead of smaller dot
            if isTarget {
                Circle()
                    .stroke(settings.displayColor, lineWidth: gridParams.dotSize * 0.15)
                    .scaleEffect(isAnimating && isSelected ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6).repeatCount(1), value: isAnimating && isSelected)
            }
            
            // Add a subtle glow for today's date
            if Calendar.current.isDateInToday(date) {
                Circle()
                    .fill(settings.displayColor)
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
            
            ZStack {
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
                
                // Overlay for date tooltip
                if let date = selectedDate, let index = tappedIndex {
                    let row = index / gridParams.columns
                    let col = index % gridParams.columns
                    
                    // Calculate dot position
                    let dotX = CGFloat(col) * gridParams.dotSize + gridParams.dotSize/2
                    let dotY = CGFloat(row) * gridParams.dotSize + gridParams.dotSize/2
                    
                    // Always position the tooltip above the dot with proper spacing
                    // Use a minimum offset from the top of the view to ensure visibility
                    let tooltipOffset = dotY < 40 ? max(10, dotY - 10) : dotY - 30
                    
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
                        .position(x: dotX, y: tooltipOffset)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .scale(scale: 0.8).combined(with: .opacity)
                        ))
                }
            }
        }
    }
}

