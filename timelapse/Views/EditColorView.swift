import SwiftUI

struct EditColorView: View {
    @Environment(\.dismiss) private var dismiss
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
            selectedColor = Color(hex: hexValue)
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
        let defaultColor = displayColor.resetToDefault()
        selectedColor = defaultColor.color
        colorName = defaultColor.name
        hexValue = defaultColor.color.hexString
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
        NavigationView {
            Form {
                Section(header: Text("Color Name")) {
                    TextField("Enter color name", text: $colorName)
                        .autocapitalization(.words)
                }
                
                Section(header: Text("Color Wheel")) {
                    VStack {
                        ColorPicker("Select Color", selection: $selectedColor)
                            .padding()
                            .onChange(of: selectedColor) { oldValue, newValue in
                                hexValue = newValue.hexString
                            }
                        
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedColor)
                            .frame(height: 100)
                            .padding()
                    }
                }
                
                Section(header: Text("Hex Color Code")) {
                    HStack {
                        Text("#")
                        TextField("Enter hex code (e.g., 7F3DE8)", text: $hexValue)
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
                                updateFromHex()
                            } else {
                                showAlert = true
                                alertMessage = "Please enter a 6-digit hex color"
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    if !displayColor.isUsingDefaultValues() {
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
            .navigationTitle("Edit \(displayColor.name)")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Done") { saveColor() }
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
                Text("This will reset this color to its factory default. This action cannot be undone.")
            }
        }
    }
}

#Preview {
    EditColorView(
        displayColor: DisplayColor(id: "orange", name: "Orange", color: Color(hex: "FF7F00")),
        needsRefresh: .constant(false),
        eventStore: EventStore()
    )
} 