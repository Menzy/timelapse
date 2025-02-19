import SwiftUI

struct CustomizeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var settings: DisplaySettings
    @State private var showingColorPicker = false
    @EnvironmentObject var globalSettings: GlobalSettings // Use global settings
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display Style") {
                    Picker("Style", selection: $settings.style) {
                        ForEach(TimeDisplayStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized).tag(style)
                        }
                    }
                    
                    Picker("Color", selection: $settings.displayColor) {
                        let presets = DisplayColor.getPresets(for: globalSettings.backgroundStyle)
                        ForEach(presets) { preset in
                            HStack {
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 20, height: 20)
                                Text(preset.name)
                            }
                            .tag(preset.color)
                        }
                    }
                    .disabled(settings.style == .countdown)
                    .onChange(of: settings.displayColor) { oldValue, newValue in
                        // Update isUsingDefaultColor based on selection
                        let defaultColor = Color(hex: "FF7F00")
                        settings.isUsingDefaultColor = (newValue == defaultColor)
                        settings.objectWillChange.send()
                    }
                    .onChange(of: settings.style) { oldStyle, newStyle in
                        // Ensure color persists when changing styles
                        if !settings.isUsingDefaultColor {
                            settings.displayColor = settings.displayColor
                        }
                        settings.objectWillChange.send()
                    }
                }
                
                Section("Background Theme") {
                    Picker("Theme", selection: $globalSettings.backgroundStyle) { // Modify global settings
                        ForEach(BackgroundStyle.allCases, id: \.self) { style in
                            Text(style.rawValue.capitalized).tag(style)
                        }
                    }
                    .onChange(of: globalSettings.backgroundStyle) { oldStyle, newStyle in
                        settings.updateColor(for: newStyle)
                        settings.objectWillChange.send()
                    }
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
