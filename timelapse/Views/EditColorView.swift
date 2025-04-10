import SwiftUI

struct EditColorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var displayColor: DisplayColor
    @State private var colorName: String
    @State private var selectedColor: Color
    @State private var hexValue: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showResetConfirmation = false
    @Binding var needsRefresh: Bool
    
    // Add event store reference to update year tracker
    private let eventStore: EventStore
    
    init(displayColor: DisplayColor, needsRefresh: Binding<Bool>, eventStore: EventStore) {
        _displayColor = State(initialValue: displayColor)
        _colorName = State(initialValue: displayColor.name)
        _selectedColor = State(initialValue: displayColor.color)
        _hexValue = State(initialValue: displayColor.color.hexString)
        _needsRefresh = needsRefresh
        self.eventStore = eventStore
    }
    
    private func isValidHex(_ hex: String) -> Bool {
        let pattern = "^[0-9A-Fa-f]{6}$"
        let regex = try! NSRegularExpression(pattern: pattern)
        let range = NSRange(hex.startIndex..., in: hex)
        return regex.firstMatch(in: hex, range: range) != nil
    }
    
    private func updateFromHex() {
        if isValidHex(hexValue) {
            withAnimation(.easeInOut(duration: 0.3)) {
                selectedColor = Color(hex: hexValue)
            }
        } else {
            showAlert = true
            alertMessage = "Please enter a valid 6-digit hex color (e.g., 7F3DE8)"
        }
    }
    
    private func saveColor() {
        var updatedColor = displayColor
        updatedColor.name = colorName.isEmpty ? displayColor.name : colorName
        updatedColor.color = selectedColor
        
        // Save the color change to UserDefaults
        updatedColor.saveEdits()
        
        // This forces a UI refresh in the customize view
        needsRefresh = true
        
        // Ensure the year tracker gets updated if using this color
        updateYearTrackerIfNeeded()
        
        dismiss()
    }
    
    // Reset to default values
    private func resetToDefault() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let defaultColor = displayColor.resetToDefault()
            selectedColor = defaultColor.color
            colorName = defaultColor.name
            hexValue = defaultColor.color.hexString
        }
    }
    
    // Update the year tracker if it's using this color
    private func updateYearTrackerIfNeeded() {
        // Check if the year tracker color matches the color we're editing
        if let yearTrackerHex = UserDefaults.standard.string(forKey: "yearTrackerDisplayColorHex") {
            let isYearTrackerUsingThisColor = displayColor.matchesHexColor(hex: yearTrackerHex)
            
            if isYearTrackerUsingThisColor {
                // Update the year tracker color directly in UserDefaults
                UserDefaults.standard.set(selectedColor.hexString, forKey: "yearTrackerDisplayColorHex")
                UserDefaults.standard.set(false, forKey: "yearTrackerIsUsingDefaultColor")
                
                // Post a special notification for the year tracker
                NotificationCenter.default.post(
                    name: Notification.Name("YearTrackerDisplayColorChanged"),
                    object: nil,
                    userInfo: ["newColor": selectedColor]
                )
            }
        }
        
        // Update any event using this color
        for (_, settings) in eventStore.displaySettings {
            let currentHex = settings.displayColor.hexString
            if displayColor.matchesHexColor(hex: currentHex) {
                settings.displayColor = selectedColor
                settings.isUsingDefaultColor = false
            }
        }
        
        // Save all display settings to persist these changes
        eventStore.saveDisplaySettings()
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Enhanced color preview section
                Section {
                    VStack(spacing: 16) {
                        // Dynamic color preview with light/dark demonstration
                        HStack(spacing: 12) {
                            // Light background preview
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .frame(height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 50, height: 50)
                            }
                            
                            // Dark background preview
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black)
                                    .frame(height: 80)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                
                                Circle()
                                    .fill(selectedColor)
                                    .frame(width: 50, height: 50)
                            }
                        }
                        
                        // Full-width color preview
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedColor)
                            .frame(height: 80)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: selectedColor.opacity(0.5), radius: 8, x: 0, y: 2)
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16))
                }
                
                Section {
                    TextField("Enter color name", text: $colorName)
                        .font(.headline)
                        .padding(.vertical, 4)
                        .autocapitalization(.words)
                } header: {
                    Text("Name")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
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
                    HStack {
                        Text("#")
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        TextField("Enter hex value", text: $hexValue)
                            .font(.system(.body, design: .monospaced))
                            .keyboardType(.asciiCapable)
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
                        
                        Spacer()
                        
                        Button(action: updateFromHex) {
                            Text("Apply")
                                .fontWeight(.medium)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(selectedColor)
                        .foregroundColor(selectedColor.isBright() ? .black : .white)
                        .disabled(hexValue.count != 6)
                    }
                } header: {
                    Text("Hex value")
                        .textCase(.uppercase)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } footer: {
                    Text("Enter a 6-digit hex color code (e.g., 7F3DE8)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !displayColor.isUsingDefaultValues() {
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
            .navigationTitle("Edit \(displayColor.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveColor() }
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
                Text("This will reset this color to its factory default. This action cannot be undone.")
            }
        }
    }
}

// Extension to check color brightness for appropriate text color 
extension Color {
    func isBright() -> Bool {
        let uiColor = UIColor(self)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Calculate perceived brightness
        let brightness = (0.299 * red + 0.587 * green + 0.114 * blue)
        return brightness > 0.7
    }
}

#Preview {
    EditColorView(
        displayColor: DisplayColor(id: "orange", name: "Orange", color: Color(hex: "FF7F00")),
        needsRefresh: .constant(false),
        eventStore: EventStore()
    )
    .environmentObject(GlobalSettings())
} 