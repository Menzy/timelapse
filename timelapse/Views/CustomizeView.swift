import SwiftUI

struct ThemeCircleView: View {
    let style: BackgroundStyle
    let isSelected: Bool
    
    var body: some View {
        VStack {
            ZStack {
                // Selection border
                Circle()
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                if style == .device {
                    // Split circle for device theme
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 30, height: 60)
                        Rectangle()
                            .fill(Color(hex: "111111"))
                            .frame(width: 30, height: 60)
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
            .frame(width: 60, height: 60)
            
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
        let defaultColor = Color(hex: "FF7F00")
        return globalSettings.effectiveBackgroundStyle == .light ? defaultColor : defaultColor
    }
    
    var body: some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                    .frame(width: 60, height: 60)
                
                switch style {
                case .dotPixels:
                    Circle()
                        .fill(iconColor)
                        .frame(width: 40, height: 40)
                case .triGrid:
                    Triangle()
                        .fill(iconColor)
                        .frame(width: 40, height: 40)
                case .progressBar:
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(iconColor)
                            .frame(width: 25, height: 30)
                        Rectangle()
                            .fill(iconColor.opacity(0.3))
                            .frame(width: 15, height: 30)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                case .countdown:
                    Text("365")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(iconColor)
                }
            }
            .frame(width: 60, height: 60)
            
            Text(style.rawValue.capitalized)
                .font(.inter(12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct CustomizeView: View {
    @Environment(\.dismiss) private var dismiss: DismissAction
    @ObservedObject var settings: DisplaySettings
    @State private var showingColorPicker = false
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Style") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 4), spacing: 20) {
                        ForEach(TimeDisplayStyle.allCases, id: \.self) { style in
                            StylePreviewView(style: style, isSelected: settings.style == style)
                                .onTapGesture {
                                    settings.style = style
                                }
                        }
                    }
                    .padding(.vertical, 10)
                    
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                        let presets = DisplayColor.getPresets(for: globalSettings.backgroundStyle)
                        ForEach(presets) { preset in
                            VStack {
                                ZStack {
                                    Circle()
                                        .stroke(settings.displayColor == preset.color ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                                        .frame(width: 60, height: 60)
                                    
                                    Circle()
                                        .fill(preset.color)
                                        .frame(width: 60, height: 60)
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
                    .onChange(of: settings.displayColor) { oldValue, newValue in
                        let defaultColor = Color(hex: "FF7F00")
                        settings.isUsingDefaultColor = (newValue == defaultColor)
                        settings.objectWillChange.send()
                    }
                    .onChange(of: settings.style) { oldStyle, newStyle in
                        if !settings.isUsingDefaultColor {
                            settings.displayColor = settings.displayColor
                        }
                        settings.objectWillChange.send()
                    }
                }
                
                Section("Background Theme") {
                    LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 20) {
                        ForEach(BackgroundStyle.allCases, id: \.self) { style in
                            ThemeCircleView(style: style, isSelected: globalSettings.backgroundStyle == style)
                                .onTapGesture {
                                    globalSettings.backgroundStyle = style
                                }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                Section("Counter") {
                    Toggle("Toggle Percentage", isOn: $settings.showPercentage)
                }
            }
            .navigationTitle("Customize")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
