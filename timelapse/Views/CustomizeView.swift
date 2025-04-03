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
    let onDoubleTap: () -> Void
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var paymentManager = PaymentManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    // Selection border
                    Circle()
                        .stroke(isSelected ? (colorScheme == .dark ? Color.white : Color.black) : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(maxWidth: 60, maxHeight: 60)
                    
                    // Background fill
                    if style == .light {
                        Circle()
                            .fill(Color.white)
                            .frame(maxWidth: 60, maxHeight: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else if style == .dark {
                        Circle()
                            .fill(Color(hex: "111111"))
                            .frame(maxWidth: 60, maxHeight: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else if style == .navy {
                        Circle()
                            .fill(style.backgroundColor)
                            .frame(maxWidth: 60, maxHeight: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else if style == .fire || style == .dream {
                        // Use a gradient for the fire and dream styles
                        Circle()
                            .fill(style.backgroundGradient)
                            .frame(maxWidth: 60, maxHeight: 60)
                    } else if style == .device {
                        // Device style - split circle
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
                    }
                    
                    // If theme is customizable, show indicator
                    if style == .navy || style == .fire || style == .dream {
                        Circle()
                            .trim(from: 0, to: 0.15)
                            .stroke(style == .light ? Color.black : Color.white, lineWidth: 2)
                            .frame(width: 52, height: 52)
                    }
                }
                
                // Premium badge for customizable themes
                if (style == .navy || style == .fire || style == .dream) && !paymentManager.isSubscribed {
                    Text("PRO")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(4)
                        .offset(x: -2, y: -2)
                }
            }
            .frame(maxWidth: 60, maxHeight: 60)
            .onTapGesture(count: 2) {
                if style == .navy || style == .fire || style == .dream {
                    if paymentManager.isSubscribed {
                        onDoubleTap()
                    } else {
                        // This will be handled by the parent view
                    }
                }
            }
            
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
    @Environment(\.colorScheme) private var colorScheme
    
    var iconColor: Color {
        if isSelected {
            return colorScheme == .dark ? .white : .black
        } else {
            return colorScheme == .dark ? Color(hex: "343434") : Color(hex: "8E8E8E")
        }
    }
    
    var containerBackgroundColor: Color {
        return colorScheme == .dark ? Color(hex: "1B1B1B").opacity(0.5) : Color(hex: "F5F5F5")
    }
    
    var gradientColors: [Color] {
        return colorScheme == .dark ? 
            [Color.black, Color(hex: "989898")] : 
            [Color(hex: "E5E5E5"), Color(hex: "CCCCCC")]
    }
    
    var body: some View {
        VStack {
            ZStack {
                // Selection border
                Circle()
                    .stroke(isSelected ? (colorScheme == .dark ? Color.white : Color.black) : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(maxWidth: 60, maxHeight: 60)
                
                // Background fill
                Circle()
                    .fill(containerBackgroundColor)
                    .frame(maxWidth: 60, maxHeight: 60)
                
                // Gradient stroke
                Circle()
                    .stroke(
                        RadialGradient(
                            gradient: Gradient(colors: gradientColors),
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
                        .font(.custom("Galgo-Bold", size: 40))
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
    @State private var selectedColorForEdit: DisplayColor? = nil
    @State private var selectedThemeForEdit: BackgroundStyle? = nil
    @State private var needsDisplayColorRefresh: Bool = false
    @State private var needsThemeRefresh: Bool = false
    @EnvironmentObject var globalSettings: GlobalSettings
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var showSubscriptionView = false
    
    private func updatePercentageForAllCards(_ showPercentage: Bool) {
        if globalSettings.isGridLayoutAvailable && globalSettings.showGridLayout {
            for eventId in eventStore.displaySettings.keys {
                eventStore.displaySettings[eventId]?.showPercentage = showPercentage
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                if !globalSettings.isGridLayoutAvailable || !globalSettings.showGridLayout {
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
                            
                            if !paymentManager.isSubscribed {
                                HStack {
                                    Text("Double-tap to edit (Premium)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.bottom, 8)
                            }
                            
                            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 15) {
                                let presets = DisplayColor.getPresets(for: globalSettings.backgroundStyle)
                                ForEach(presets) { preset in
                                    VStack {
                                        ZStack(alignment: .topTrailing) {
                                            ZStack {
                                                if settings.displayColor == preset.color {
                                                    // Glow effect for selected color
                                                    RoundedRectangle(cornerRadius: 10)
                                                        .fill(preset.color)
                                                        .frame(maxWidth: 92, maxHeight: 19)
                                                        .shadow(color: preset.color.opacity(0.5), radius: 8, x: 0, y: 0)
                                                        .shadow(color: preset.color.opacity(0.3), radius: 4, x: 0, y: 0)
                                                }
                                                
                                                RoundedRectangle(cornerRadius: 10)
                                                    .stroke(settings.displayColor == preset.color ? 
                                                        (globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white) : 
                                                        Color.gray.opacity(0.3), 
                                                        lineWidth: settings.displayColor == preset.color ? 2 : 1)
                                                    .frame(maxWidth: 92, maxHeight: 19)
                                                
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(preset.color)
                                                    .frame(maxWidth: 92, maxHeight: 19)
                                                    .frame(height: 19)
                                            }
                                            
                                            // Premium badge (only shown for non-subscribers)
                                            if !paymentManager.isSubscribed {
                                                Text("PRO")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .padding(.horizontal, 4)
                                                    .padding(.vertical, 2)
                                                    .background(Color.yellow)
                                                    .foregroundColor(.black)
                                                    .cornerRadius(4)
                                                    .offset(x: -2, y: -4)
                                            }
                                        }
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3)) {
                                                settings.displayColor = preset.color
                                            }
                                        }
                                        .onTapGesture(count: 2) {
                                            // Double tap to edit - Pro feature
                                            if paymentManager.isSubscribed {
                                                selectedColorForEdit = preset
                                            } else {
                                                showSubscriptionView = true
                                            }
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
                        .onChange(of: needsDisplayColorRefresh) { oldValue, newValue in
                            if newValue {
                                // Force a refresh of the view
                                needsDisplayColorRefresh = false
                            }
                        }
                    }
                }
                
                Section("Background Theme") {
                    if !paymentManager.isSubscribed {
                        HStack {
                            Text("Double-tap customizable themes to edit (Premium)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .padding(.bottom, 8)
                    }
                    
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 15) {
                        ForEach(BackgroundStyle.allCases, id: \.self) { style in
                            ThemeCircleView(style: style, isSelected: globalSettings.backgroundStyle == style, onDoubleTap: {
                                // Double-tap handler
                                if style == .navy || style == .fire || style == .dream {
                                    selectedThemeForEdit = style
                                }
                            })
                            .environmentObject(globalSettings)
                            .onTapGesture {
                                globalSettings.backgroundStyle = style
                                globalSettings.saveSettings()
                                eventStore.saveDisplaySettings()
                            }
                            .onTapGesture(count: 2) {
                                if (style == .navy || style == .fire || style == .dream) && !paymentManager.isSubscribed {
                                    showSubscriptionView = true
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                    .onChange(of: needsThemeRefresh) { oldValue, newValue in
                        if newValue {
                            // Force a refresh of the view
                            needsThemeRefresh = false
                        }
                    }
                }
                
                Section("Counter") {
                    Toggle("Show Percentage left", isOn: Binding(
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
            .sheet(isPresented: Binding<Bool>(
                get: { selectedColorForEdit != nil },
                set: { if !$0 { selectedColorForEdit = nil } }
            )) {
                if let colorToEdit = selectedColorForEdit {
                    EditColorView(
                        displayColor: colorToEdit,
                        needsRefresh: $needsDisplayColorRefresh,
                        eventStore: eventStore
                    )
                    .environmentObject(globalSettings)
                }
            }
            .sheet(isPresented: Binding<Bool>(
                get: { selectedThemeForEdit != nil },
                set: { if !$0 { selectedThemeForEdit = nil } }
            )) {
                if let themeToEdit = selectedThemeForEdit {
                    EditThemeView(theme: themeToEdit)
                        .environmentObject(globalSettings)
                        .onDisappear {
                            needsThemeRefresh = true
                        }
                }
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Set up theme change notifications
            setupThemeChangeObservers()
        }
    }
    
    private func setupThemeChangeObservers() {
        // Listen for theme change notifications
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NavyThemeChanged"),
            object: nil,
            queue: .main
        ) { _ in
            needsThemeRefresh = true
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("FireThemeChanged"),
            object: nil,
            queue: .main
        ) { _ in
            needsThemeRefresh = true
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("DreamThemeChanged"),
            object: nil,
            queue: .main
        ) { _ in
            needsThemeRefresh = true
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("AllThemesReset"),
            object: nil,
            queue: .main
        ) { _ in
            needsThemeRefresh = true
        }
    }
    
    // Helper function to convert color to hex string
    private func colorToHex(_ color: Color) -> String {
        return color.hexString
    }
}
