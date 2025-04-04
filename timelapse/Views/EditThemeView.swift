import SwiftUI

struct EditThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var theme: BackgroundStyle
    @State private var showResetConfirmation = false
    @State private var needsRefresh: Bool = false
    
    // For solid color theme
    @State private var selectedColor: Color
    @State private var hexValue: String = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // For gradient themes
    @State private var gradientStartColor: Color
    @State private var gradientEndColor: Color
    @State private var startHexValue: String = ""
    @State private var endHexValue: String = ""
    
    init(theme: BackgroundStyle) {
        self._theme = State(initialValue: theme)
        
        // Initialize colors based on theme type
        switch theme {
        case .navy:
            if let customNavyHex = UserDefaults.standard.string(forKey: "customNavyColorHex") {
                self._selectedColor = State(initialValue: Color(hex: customNavyHex))
                self._hexValue = State(initialValue: customNavyHex)
            } else {
                self._selectedColor = State(initialValue: Color(hex: BackgroundStyle.defaultNavyHex))
                self._hexValue = State(initialValue: BackgroundStyle.defaultNavyHex)
            }
            // Initialize with dummy values for unused properties
            self._gradientStartColor = State(initialValue: Color.clear)
            self._gradientEndColor = State(initialValue: Color.clear)
            
        case .fire:
            let startHex = UserDefaults.standard.string(forKey: "customFireStartHex") ?? BackgroundStyle.defaultFireStartHex
            let endHex = UserDefaults.standard.string(forKey: "customFireEndHex") ?? BackgroundStyle.defaultFireEndHex
            self._gradientStartColor = State(initialValue: Color(hex: startHex))
            self._gradientEndColor = State(initialValue: Color(hex: endHex))
            self._startHexValue = State(initialValue: startHex)
            self._endHexValue = State(initialValue: endHex)
            // Initialize with dummy values for unused properties
            self._selectedColor = State(initialValue: Color.clear)
            
        case .dream:
            let startHex = UserDefaults.standard.string(forKey: "customDreamStartHex") ?? BackgroundStyle.defaultDreamStartHex
            let endHex = UserDefaults.standard.string(forKey: "customDreamEndHex") ?? BackgroundStyle.defaultDreamEndHex
            self._gradientStartColor = State(initialValue: Color(hex: startHex))
            self._gradientEndColor = State(initialValue: Color(hex: endHex))
            self._startHexValue = State(initialValue: startHex)
            self._endHexValue = State(initialValue: endHex)
            // Initialize with dummy values for unused properties
            self._selectedColor = State(initialValue: Color.clear)
            
        default:
            // Initialize with dummy values for non-customizable themes
            self._selectedColor = State(initialValue: Color.clear)
            self._gradientStartColor = State(initialValue: Color.clear)
            self._gradientEndColor = State(initialValue: Color.clear)
        }
    }
    
    private func isValidHex(_ hex: String) -> Bool {
        let pattern = "^[0-9A-Fa-f]{6}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(hex.startIndex..., in: hex)
        return regex.firstMatch(in: hex, range: range) != nil
    }
    
    private func updateFromHex(_ hex: String, target: HexTarget) {
        if isValidHex(hex) {
            switch target {
            case .solid:
                selectedColor = Color(hex: hex)
            case .gradientStart:
                gradientStartColor = Color(hex: hex)
            case .gradientEnd:
                gradientEndColor = Color(hex: hex)
            }
        } else {
            showAlert = true
            alertMessage = "Please enter a valid 6-digit hex color (e.g., 7F3DE8)"
        }
    }
    
    private func saveTheme() {
        switch theme {
        case .navy:
            // Save solid color theme
            let notificationName = theme.saveCustomTheme(color: selectedColor)
            NotificationCenter.default.post(name: notificationName, object: nil)
            
        case .fire, .dream:
            // Save gradient theme
            let notificationName = theme.saveCustomTheme(
                gradientStart: gradientStartColor, 
                gradientEnd: gradientEndColor
            )
            NotificationCenter.default.post(name: notificationName, object: nil)
            
        default:
            break
        }
        
        // Force refresh in the parent view
        needsRefresh = true
        dismiss()
    }
    
    private func resetToDefault() {
        let notificationName = theme.resetToDefault()
        
        switch theme {
        case .navy:
            selectedColor = Color(hex: BackgroundStyle.defaultNavyHex)
            hexValue = BackgroundStyle.defaultNavyHex
            
        case .fire:
            if let defaults = theme.getDefaultGradientHex() {
                gradientStartColor = Color(hex: defaults.start)
                gradientEndColor = Color(hex: defaults.end)
                startHexValue = defaults.start
                endHexValue = defaults.end
            }
            
        case .dream:
            if let defaults = theme.getDefaultGradientHex() {
                gradientStartColor = Color(hex: defaults.start)
                gradientEndColor = Color(hex: defaults.end)
                startHexValue = defaults.start
                endHexValue = defaults.end
            }
            
        default:
            break
        }
        
        // Notify of changes
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
    
    // Target for hex color updates
    private enum HexTarget {
        case solid
        case gradientStart
        case gradientEnd
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Preview section
                Section(header: Text("Preview")) {
                    VStack {
                        if theme == .navy {
                            // Solid color preview
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedColor)
                                .frame(height: 100)
                                .padding()
                        } else {
                            // Gradient preview
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        stops: [
                                            .init(color: gradientStartColor, location: 0),
                                            .init(color: gradientEndColor, location: 0.6),
                                            .init(color: gradientEndColor, location: 1.0)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 100)
                                .padding()
                        }
                    }
                }
                
                if theme == .navy {
                    // Navy (solid color) editor
                    Section(header: Text("Color Wheel")) {
                        ColorPicker("Select Color", selection: $selectedColor)
                            .padding()
                            .onChange(of: selectedColor) { oldValue, newValue in
                                hexValue = newValue.hexString
                            }
                    }
                    
                    Section(header: Text("Hex Color Code")) {
                        HStack {
                            Text("#")
                            TextField("Enter hex code (e.g., 001524)", text: $hexValue)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: hexValue) { oldValue, newValue in
                                    // Format the hex value
                                    hexValue = newValue
                                        .uppercased()
                                        .filter { "0123456789ABCDEF".contains($0) }
                                        .prefix(6)
                                        .description
                                }
                            
                            Button("Apply") {
                                if hexValue.count == 6 {
                                    updateFromHex(hexValue, target: .solid)
                                } else {
                                    showAlert = true
                                    alertMessage = "Please enter a 6-digit hex color"
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 8)
                    }
                } else {
                    // Gradient theme editor (Fire or Dream)
                    Section(header: Text("Top Color")) {
                        ColorPicker("Select Color", selection: $gradientStartColor)
                            .padding()
                            .onChange(of: gradientStartColor) { oldValue, newValue in
                                startHexValue = newValue.hexString
                            }
                        
                        HStack {
                            Text("#")
                            TextField("Enter hex code", text: $startHexValue)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: startHexValue) { oldValue, newValue in
                                    // Format the hex value
                                    startHexValue = newValue
                                        .uppercased()
                                        .filter { "0123456789ABCDEF".contains($0) }
                                        .prefix(6)
                                        .description
                                }
                            
                            Button("Apply") {
                                if startHexValue.count == 6 {
                                    updateFromHex(startHexValue, target: .gradientStart)
                                } else {
                                    showAlert = true
                                    alertMessage = "Please enter a 6-digit hex color"
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Section(header: Text("Bottom Color")) {
                        ColorPicker("Select Color", selection: $gradientEndColor)
                            .padding()
                            .onChange(of: gradientEndColor) { oldValue, newValue in
                                endHexValue = newValue.hexString
                            }
                        
                        HStack {
                            Text("#")
                            TextField("Enter hex code", text: $endHexValue)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: endHexValue) { oldValue, newValue in
                                    // Format the hex value
                                    endHexValue = newValue
                                        .uppercased()
                                        .filter { "0123456789ABCDEF".contains($0) }
                                        .prefix(6)
                                        .description
                                }
                            
                            Button("Apply") {
                                if endHexValue.count == 6 {
                                    updateFromHex(endHexValue, target: .gradientEnd)
                                } else {
                                    showAlert = true
                                    alertMessage = "Please enter a 6-digit hex color"
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    if !theme.isUsingDefaultValues() {
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            Text("Reset to Default")
                                .frame(maxWidth: .infinity)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
            }
            .navigationTitle("Edit \(theme.rawValue.capitalized) Theme")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { saveTheme() }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Invalid Hex Code"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .confirmationDialog(
                "Reset to Default",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset to Default", role: .destructive) {
                    resetToDefault()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset this theme to its factory default. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    EditThemeView(theme: .navy)
} 