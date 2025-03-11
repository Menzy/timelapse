import SwiftUI

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

struct ThemeCircleView: View {
    let style: BackgroundStyle
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                // Selection border
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(maxWidth: 60, maxHeight: 60)
                
                if style == .device {
                    // Split circle for device theme
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(maxWidth: 30, maxHeight: 60)
                        Rectangle()
                            .fill(Color(hex: "111111"))
                            .frame(maxWidth: 30, maxHeight: 60)
                    }
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                } else if style == .fire {
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: "EC5F01"), location: 0),
                                    .init(color: Color.black, location: 0.6),
                                    .init(color: .black, location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else if style == .dream {
                    Circle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: Color(hex: "A82700"), location: 0),
                                    .init(color: Color(hex: "002728"), location: 0.6),
                                    .init(color: Color(hex: "002728"), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                } else {
                    Circle()
                        .fill(style == .light ? Color.white :
                              style == .dark ? Color(hex: "111111") :
                              style == .navy ? Color(hex: "001524") : .clear)
                        .overlay(
                            Circle()
                                .stroke(style == .light ? Color.gray.opacity(0.3) :
                                       style == .dark ? Color.gray.opacity(0.3) :
                                       style == .navy ? Color.gray.opacity(0.3) : .clear,
                                       lineWidth: 1)
                        )
                }
            }
            .frame(maxWidth: 60, maxHeight: 60)
            
            Text(style.rawValue.capitalized)
                .font(.inter(12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct StylePreviewView: View {
    let style: TimeDisplayStyle
    let isSelected: Bool
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var iconColor: Color {
        return Color(hex: "343434")
    }
    
    var gradientStroke: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(hex: "989898")]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Selection border
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(maxWidth: 60, maxHeight: 60)
                
                // Background fill
                Circle()
                    .fill(Color(hex: "1B1B1B").opacity(0.5))
                    .frame(maxWidth: 60, maxHeight: 60)
                
                // Gradient stroke
                Circle()
                    .stroke(
                        RadialGradient(
                            gradient: Gradient(colors: [Color.black, Color(hex: "989898")]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        ),
                        lineWidth: 1
                    )
                    .frame(maxWidth: 60, maxHeight: 60)
                
                switch style {
                case .dotPixels:
                    Circle()
                        .fill(iconColor)
                        .frame(maxWidth: 34, maxHeight: 34)
                case .triGrid:
                    Triangle()
                        .fill(iconColor)
                        .frame(maxWidth: 34, maxHeight: 34)
                case .progressBar:
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(iconColor)
                            .frame(width: 17, height: 22)
                        Rectangle()
                            .fill(iconColor.opacity(0.3))
                            .frame(width: 10, height: 22)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .frame(maxWidth: 34, maxHeight: 34)
                case .countdown:
                    Text("365")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(iconColor)
                        .frame(maxWidth: 34, maxHeight: 34)
                }
            }
            .frame(maxWidth: 60, maxHeight: 60)
            
            Text(style.rawValue.capitalized)
                .font(.inter(12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct CustomizeView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var settings: DisplaySettings
    @ObservedObject var eventStore: EventStore
    @State private var showingColorPicker = false
    @EnvironmentObject var globalSettings: GlobalSettings
    
    private func updatePercentageForAllCards(_ showPercentage: Bool) {
        if globalSettings.showGridLayout {
            for eventId in eventStore.displaySettings.keys {
                eventStore.displaySettings[eventId]?.showPercentage = showPercentage
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if !globalSettings.showGridLayout {
                    Section("Display Style") {
                        VStack(spacing: 0) {
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 15) {
                                ForEach(TimeDisplayStyle.allCases, id: \.self) { style in
                                    StylePreviewView(style: style, isSelected: settings.style == style)
                                        .onTapGesture {
                                            settings.style = style
                                        }
                                }
                            }
                            .padding(.vertical, 10)
                            
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 15) {
                                let presets = DisplayColor.getPresets(for: globalSettings.backgroundStyle)
                                ForEach(presets) { preset in
                                    VStack {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(settings.displayColor == preset.color ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                                .frame(maxWidth: 92, maxHeight: 19)
                                                .frame(height: 19)
                                            
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(preset.color)
                                                .frame(maxWidth: 92, maxHeight: 19)
                                                .frame(height: 19)
                                        }
                                        .onTapGesture {
                                            settings.displayColor = preset.color
                                        }
                                        
                                        Text(preset.name)
                                            .font(.inter(12, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                            .padding(.vertical, 10)
                        }
                        .onChange(of: settings.displayColor) { oldValue, newValue in
                            let defaultColor = Color(hex: "FF7F00")
                            settings.isUsingDefaultColor = (newValue == defaultColor)
                            settings.objectWillChange.send()
                            eventStore.saveDisplaySettings()
                        }
                        .onChange(of: settings.style) { oldStyle, newStyle in
                            if !settings.isUsingDefaultColor {
                                settings.displayColor = settings.displayColor
                            }
                            settings.objectWillChange.send()
                            eventStore.saveDisplaySettings()
                        }
                    }
                }
                
                Section("Background Theme") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 15) {
                        ForEach(BackgroundStyle.allCases, id: \.self) { style in
                            ThemeCircleView(style: style, isSelected: globalSettings.backgroundStyle == style)
                                .onTapGesture {
                                    globalSettings.backgroundStyle = style
                                    globalSettings.saveSettings()
                                    eventStore.saveDisplaySettings()
                                }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Section("Counter") {
                    Toggle("Toggle Percentage", isOn: Binding(
                        get: { settings.showPercentage },
                        set: { newValue in
                            settings.showPercentage = newValue
                            updatePercentageForAllCards(newValue)
                            eventStore.saveDisplaySettings()
                        }
                    ))
                }
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
