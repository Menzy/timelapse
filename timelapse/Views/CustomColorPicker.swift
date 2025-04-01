import SwiftUI

struct CustomColorPicker: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings
    @State private var selectedColor: Color
    @State private var hexValue: String
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Change from @ObservedObject to regular properties
    private var settings: DisplaySettings?
    private var eventStore: EventStore?
    
    init(initialColor: Color, initialHex: String, settings: DisplaySettings? = nil, eventStore: EventStore? = nil) {
        _selectedColor = State(initialValue: initialColor)
        _hexValue = State(initialValue: initialHex)
        self.settings = settings
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
    
    // Function to convert Color to hex string
    private func colorToHex(_ color: Color) -> String {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let hexString = String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )
        return hexString
    }
    
    private func saveColor() {
        let hexString = colorToHex(selectedColor)
        
        // If this is for a specific event's display color
        if let settings = settings, let eventStore = eventStore {
            settings.displayColor = selectedColor
            settings.isUsingDefaultColor = false
            eventStore.saveDisplaySettings()
        }
        
        // Save to UserDefaults (no longer using GlobalSettings for this)
        UserDefaults.standard.set(hexString, forKey: "customDisplayColorHex")
        
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Color Wheel")) {
                    VStack {
                        ColorPicker("Select Color", selection: $selectedColor)
                            .padding()
                            .onChange(of: selectedColor) { oldValue, newValue in
                                hexValue = colorToHex(newValue)
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
                    Button("Save Custom Color") {
                        saveColor()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Custom Color")
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
        }
    }
}

#Preview {
    CustomColorPicker(initialColor: Color(hex: "7F3DE8"), initialHex: "7F3DE8")
        .environmentObject(GlobalSettings())
} 