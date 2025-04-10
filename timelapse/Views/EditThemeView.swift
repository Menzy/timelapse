import SwiftUI

struct EditThemeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
            withAnimation(.easeInOut(duration: 0.3)) {
                switch target {
                case .solid:
                    selectedColor = Color(hex: hex)
                case .gradientStart:
                    gradientStartColor = Color(hex: hex)
                case .gradientEnd:
                    gradientEndColor = Color(hex: hex)
                }
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
        
        withAnimation(.easeInOut(duration: 0.3)) {
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
    
    // Function to create a reusable hex input view
    private func hexInputField(value: Binding<String>, target: HexTarget, label: String) -> some View {
        HStack {
            Text("#")
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.secondary)
            
            TextField("Enter hex value", text: value)
                .font(.system(.body, design: .monospaced))
                .keyboardType(.asciiCapable)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: value.wrappedValue) { oldValue, newValue in
                    // Format the hex value
                    value.wrappedValue = newValue
                        .uppercased()
                        .filter { "0123456789ABCDEF".contains($0) }
                        .prefix(6)
                        .description
                }
            
            Spacer()
            
            Button {
                if value.wrappedValue.count == 6 {
                    updateFromHex(value.wrappedValue, target: target)
                } else {
                    showAlert = true
                    alertMessage = "Please enter a 6-digit hex color"
                }
            } label: {
                Text("Apply")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(target == .solid ? selectedColor :
                    target == .gradientStart ? gradientStartColor : gradientEndColor)
            .foregroundColor((target == .solid ? selectedColor :
                               target == .gradientStart ? gradientStartColor : gradientEndColor).isBright() ? .black : .white)
            .disabled(value.wrappedValue.count != 6)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Preview section with enhanced visuals
                Section {
                    VStack(spacing: 16) {
                        if theme == .navy {
                            // Solid color preview with device frame
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(selectedColor)
                                    .frame(height: 150)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Mock device UI elements
                                VStack(spacing: 12) {
                                    Circle()
                                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 20)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 70, height: 20)
                                }
                            }
                            .shadow(color: selectedColor.opacity(0.5), radius: 10, x: 0, y: 5)
                        } else {
                            // Gradient preview with device frame
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
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
                                    .frame(height: 150)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                
                                // Mock device UI elements
                                VStack(spacing: 12) {
                                    Circle()
                                        .stroke(Color.white.opacity(0.7), lineWidth: 2)
                                        .frame(width: 50, height: 50)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 100, height: 20)
                                    
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.white.opacity(0.15))
                                        .frame(width: 70, height: 20)
                                }
                            }
                            .shadow(radius: 10)
                            
                            // Display the gradient stops visually
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(gradientStartColor)
                                    .frame(height: 12)
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [gradientStartColor, gradientEndColor],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(height: 12)
                                Rectangle()
                                    .fill(gradientEndColor)
                                    .frame(height: 12)
                            }
                            .cornerRadius(6)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                } header: {
                    Text("Theme preview")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if theme == .navy {
                    // Navy (solid color) editor
                    Section {
                        ColorPicker("Select color", selection: $selectedColor)
                            .padding(.vertical, 8)
                            .onChange(of: selectedColor) { oldValue, newValue in
                                hexValue = newValue.hexString
                            }
                    } header: {
                        Text("Color picker")
                            .textCase(.uppercase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        hexInputField(value: $hexValue, target: .solid, label: "Hex Value")
                    } header: {
                        Text("Hex value")
                            .textCase(.uppercase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } footer: {
                        Text("Enter a 6-digit hex color code (e.g., 001524)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    // Gradient theme editor (Fire or Dream)
                    Section {
                        ColorPicker("Select color", selection: $gradientStartColor)
                            .padding(.vertical, 8)
                            .onChange(of: gradientStartColor) { oldValue, newValue in
                                startHexValue = newValue.hexString
                            }
                        
                        hexInputField(value: $startHexValue, target: .gradientStart, label: "Top Color")
                    } header: {
                        Text("Top gradient color")
                            .textCase(.uppercase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Section {
                        ColorPicker("Select color", selection: $gradientEndColor)
                            .padding(.vertical, 8)
                            .onChange(of: gradientEndColor) { oldValue, newValue in
                                endHexValue = newValue.hexString
                            }
                        
                        hexInputField(value: $endHexValue, target: .gradientEnd, label: "Bottom Color")
                    } header: {
                        Text("Bottom gradient color")
                            .textCase(.uppercase)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !theme.isUsingDefaultValues() {
                    Section {
                        Button(role: .destructive) {
                            showResetConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Reset to Default")
                                    .fontWeight(.medium)
                                Spacer()
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Edit \(theme.rawValue.capitalized) Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveTheme() }
                        .fontWeight(.semibold)
                }
            }
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
        .environmentObject(GlobalSettings())
} 