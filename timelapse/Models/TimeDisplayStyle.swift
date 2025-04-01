import SwiftUI

enum TimeDisplayStyle: String, CaseIterable, Codable {
    case dotPixels
    case triGrid
    case progressBar
    case countdown
}

enum BackgroundStyle: String, CaseIterable, Codable {
    case light
    case dark
    case navy
    case fire
    case dream
    case device
    
    // Default theme color constants
    static let defaultNavyHex = "001524"
    static let defaultFireStartHex = "EC5F01"
    static let defaultFireEndHex = "000000"
    static let defaultDreamStartHex = "A82700"
    static let defaultDreamEndHex = "002728"
    
    var backgroundColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return Color(hex: "111111")
        case .navy:
            // Use custom navy color if available
            if let customNavyHex = UserDefaults.standard.string(forKey: "customNavyColorHex") {
                return Color(hex: customNavyHex)
            }
            return Color(hex: BackgroundStyle.defaultNavyHex)
        case .fire, .dream:
            // For gradient themes, return the bottom color
            return self == .fire ? 
                Color(hex: UserDefaults.standard.string(forKey: "customFireEndHex") ?? BackgroundStyle.defaultFireEndHex) :
                Color(hex: UserDefaults.standard.string(forKey: "customDreamEndHex") ?? BackgroundStyle.defaultDreamEndHex)
        case .device:
            return Color.primary
        }
    }
    
    // Get gradient colors for themes that use gradients
    func getGradientColors() -> (start: Color, end: Color)? {
        switch self {
        case .fire:
            let startHex = UserDefaults.standard.string(forKey: "customFireStartHex") ?? BackgroundStyle.defaultFireStartHex
            let endHex = UserDefaults.standard.string(forKey: "customFireEndHex") ?? BackgroundStyle.defaultFireEndHex
            return (Color(hex: startHex), Color(hex: endHex))
            
        case .dream:
            let startHex = UserDefaults.standard.string(forKey: "customDreamStartHex") ?? BackgroundStyle.defaultDreamStartHex
            let endHex = UserDefaults.standard.string(forKey: "customDreamEndHex") ?? BackgroundStyle.defaultDreamEndHex
            return (Color(hex: startHex), Color(hex: endHex))
            
        default:
            return nil
        }
    }
    
    // Get the default hex value for this theme
    func getDefaultHex() -> String? {
        switch self {
        case .navy:
            return BackgroundStyle.defaultNavyHex
        default:
            return nil
        }
    }
    
    // Get the default gradient colors for this theme
    func getDefaultGradientHex() -> (start: String, end: String)? {
        switch self {
        case .fire:
            return (BackgroundStyle.defaultFireStartHex, BackgroundStyle.defaultFireEndHex)
        case .dream:
            return (BackgroundStyle.defaultDreamStartHex, BackgroundStyle.defaultDreamEndHex)
        default:
            return nil
        }
    }
    
    // Check if this theme is using its default values
    func isUsingDefaultValues() -> Bool {
        switch self {
        case .navy:
            if let customNavyHex = UserDefaults.standard.string(forKey: "customNavyColorHex") {
                return customNavyHex.uppercased() == BackgroundStyle.defaultNavyHex.uppercased()
            }
            return true
            
        case .fire:
            let customStartHex = UserDefaults.standard.string(forKey: "customFireStartHex")?.uppercased()
            let customEndHex = UserDefaults.standard.string(forKey: "customFireEndHex")?.uppercased()
            return (customStartHex == BackgroundStyle.defaultFireStartHex.uppercased() || customStartHex == nil) &&
                   (customEndHex == BackgroundStyle.defaultFireEndHex.uppercased() || customEndHex == nil)
            
        case .dream:
            let customStartHex = UserDefaults.standard.string(forKey: "customDreamStartHex")?.uppercased()
            let customEndHex = UserDefaults.standard.string(forKey: "customDreamEndHex")?.uppercased()
            return (customStartHex == BackgroundStyle.defaultDreamStartHex.uppercased() || customStartHex == nil) &&
                   (customEndHex == BackgroundStyle.defaultDreamEndHex.uppercased() || customEndHex == nil)
            
        default:
            return true
        }
    }
    
    // Reset this theme to its default values and return notification name
    func resetToDefault() -> Notification.Name {
        switch self {
        case .navy:
            UserDefaults.standard.removeObject(forKey: "customNavyColorHex")
            return Notification.Name("NavyThemeReset")
            
        case .fire:
            UserDefaults.standard.removeObject(forKey: "customFireStartHex")
            UserDefaults.standard.removeObject(forKey: "customFireEndHex")
            return Notification.Name("FireThemeReset")
            
        case .dream:
            UserDefaults.standard.removeObject(forKey: "customDreamStartHex")
            UserDefaults.standard.removeObject(forKey: "customDreamEndHex")
            return Notification.Name("DreamThemeReset")
            
        default:
            return Notification.Name("ThemeReset")
        }
    }
    
    // Save custom theme settings and return notification name
    func saveCustomTheme(color: Color? = nil, gradientStart: Color? = nil, gradientEnd: Color? = nil) -> Notification.Name {
        switch self {
        case .navy:
            if let color = color {
                UserDefaults.standard.set(color.hexString, forKey: "customNavyColorHex")
            }
            return Notification.Name("NavyThemeChanged")
            
        case .fire:
            if let start = gradientStart, let end = gradientEnd {
                UserDefaults.standard.set(start.hexString, forKey: "customFireStartHex")
                UserDefaults.standard.set(end.hexString, forKey: "customFireEndHex")
            }
            return Notification.Name("FireThemeChanged")
            
        case .dream:
            if let start = gradientStart, let end = gradientEnd {
                UserDefaults.standard.set(start.hexString, forKey: "customDreamStartHex")
                UserDefaults.standard.set(end.hexString, forKey: "customDreamEndHex")
            }
            return Notification.Name("DreamThemeChanged")
            
        default:
            return Notification.Name("ThemeChanged")
        }
    }
    
    // Reset all customizable themes to their defaults
    static func resetAllThemesToDefaults() {
        // Reset Navy theme
        UserDefaults.standard.removeObject(forKey: "customNavyColorHex")
        
        // Reset Fire theme
        UserDefaults.standard.removeObject(forKey: "customFireStartHex")
        UserDefaults.standard.removeObject(forKey: "customFireEndHex")
        
        // Reset Dream theme
        UserDefaults.standard.removeObject(forKey: "customDreamStartHex")
        UserDefaults.standard.removeObject(forKey: "customDreamEndHex")
        
        // Post notification to refresh all views
        NotificationCenter.default.post(name: Notification.Name("AllThemesReset"), object: nil)
    }
}

struct DisplayColor: Identifiable {
    let id: String
    var name: String
    var color: Color
    let isEditable: Bool
    
    // Default color constants
    static let defaultOrangeHex = "FF7F00"
    static let defaultBlueHex = "008CFF"
    static let defaultGreenHex = "7FBF54"
    
    static let defaultColorNames = [
        "orange": "Orange",
        "blue": "Blue",
        "green": "Green"
    ]
    
    init(id: String, name: String, color: Color, isEditable: Bool = true) {
        self.id = id
        self.name = name
        self.color = color
        self.isEditable = isEditable
    }
    
    static func getPresets(for backgroundStyle: BackgroundStyle) -> [DisplayColor] {
        // Get user's custom colors from UserDefaults if available
        let orangeColor = getUserColor(for: "orange", defaultHex: defaultOrangeHex)
        let orangeName = UserDefaults.standard.string(forKey: "orangeColorName") ?? defaultColorNames["orange"]!
        
        let blueColor = getUserColor(for: "blue", defaultHex: defaultBlueHex)
        let blueName = UserDefaults.standard.string(forKey: "blueColorName") ?? defaultColorNames["blue"]!
        
        let greenColor = getUserColor(for: "green", defaultHex: defaultGreenHex)
        let greenName = UserDefaults.standard.string(forKey: "greenColorName") ?? defaultColorNames["green"]!
        
        return [
            DisplayColor(id: "orange", name: orangeName, color: orangeColor),
            DisplayColor(id: "blue", name: blueName, color: blueColor),
            DisplayColor(id: "green", name: greenName, color: greenColor)
        ]
    }
    
    // Helper to create color from hex
    static func color(hex: String) -> Color {
        Color(hex: hex)
    }
    
    // Helper to get user's custom color value from UserDefaults
    private static func getUserColor(for colorID: String, defaultHex: String) -> Color {
        if let savedHex = UserDefaults.standard.string(forKey: "\(colorID)ColorHex") {
            return Color(hex: savedHex)
        }
        return Color(hex: defaultHex)
    }
    
    // Save the edits to UserDefaults and post notification to update all displays
    func saveEdits() {
        // Save the updated color and name to UserDefaults
        UserDefaults.standard.set(color.hexString, forKey: "\(id)ColorHex")
        UserDefaults.standard.set(name, forKey: "\(id)ColorName")
        
        // Post a notification to update all views using this color
        NotificationCenter.default.post(name: Notification.Name("DisplayColorChanged"), 
                                        object: nil,
                                        userInfo: ["colorID": id, "newColor": color])
    }
    
    // Get the default hex value for this color
    func getDefaultHex() -> String {
        switch id {
        case "orange":
            return DisplayColor.defaultOrangeHex
        case "blue":
            return DisplayColor.defaultBlueHex
        case "green":
            return DisplayColor.defaultGreenHex
        default:
            return DisplayColor.defaultOrangeHex
        }
    }
    
    // Get the default name for this color
    func getDefaultName() -> String {
        return DisplayColor.defaultColorNames[id] ?? "Color"
    }
    
    // Reset this color to its default values
    func resetToDefault() -> DisplayColor {
        var resetColor = self
        resetColor.color = Color(hex: getDefaultHex())
        resetColor.name = getDefaultName()
        return resetColor
    }
    
    // Check if this color is using its default values
    func isUsingDefaultValues() -> Bool {
        let defaultHex = getDefaultHex()
        let defaultName = getDefaultName()
        return color.hexString.uppercased() == defaultHex.uppercased() && name == defaultName
    }
    
    // Check if this display color matches another color
    func matchesHexColor(hex: String) -> Bool {
        return color.hexString.uppercased() == hex.uppercased()
    }
    
    // Find which color preset (if any) matches a given color
    static func findMatchingPreset(for targetColor: Color) -> DisplayColor? {
        let presets = getPresets(for: .dark) // Background style doesn't matter for this check
        let targetHex = targetColor.hexString
        
        // Try to find an exact match
        for preset in presets {
            if preset.matchesHexColor(hex: targetHex) {
                return preset
            }
        }
        
        return nil
    }
    
    // Reset all display colors to their default values
    static func resetAllColorsToDefaults() {
        // Reset orange color
        let defaultOrange = DisplayColor(id: "orange", name: defaultColorNames["orange"]!, color: Color(hex: defaultOrangeHex))
        defaultOrange.saveEdits()
        UserDefaults.standard.removeObject(forKey: "orangeColorHex")
        UserDefaults.standard.removeObject(forKey: "orangeColorName")
        
        // Reset blue color
        let defaultBlue = DisplayColor(id: "blue", name: defaultColorNames["blue"]!, color: Color(hex: defaultBlueHex))
        defaultBlue.saveEdits()
        UserDefaults.standard.removeObject(forKey: "blueColorHex")
        UserDefaults.standard.removeObject(forKey: "blueColorName")
        
        // Reset green color
        let defaultGreen = DisplayColor(id: "green", name: defaultColorNames["green"]!, color: Color(hex: defaultGreenHex))
        defaultGreen.saveEdits()
        UserDefaults.standard.removeObject(forKey: "greenColorHex")
        UserDefaults.standard.removeObject(forKey: "greenColorName")
        
        // Post notification to refresh all views
        NotificationCenter.default.post(name: Notification.Name("AllDisplayColorsReset"), object: nil)
    }
}

class DisplaySettings: ObservableObject, Identifiable, Codable {
    private let _id: UUID
    var id: UUID { _id }
    @Published var style: TimeDisplayStyle = .dotPixels
    @Published var showPercentage = false
    @Published var displayColor: Color = Color(hex: "FF7F00")
    @Published var backgroundStyle: BackgroundStyle = .dark
    @Published var isUsingDefaultColor: Bool = true
    // Track which color preset this display is using
    private var associatedColorID: String? = "orange" // Default to orange
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case style
        case showPercentage
        case displayColor
        case backgroundStyle
        case isUsingDefaultColor
        case associatedColorID
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        style = try container.decode(TimeDisplayStyle.self, forKey: .style)
        showPercentage = try container.decode(Bool.self, forKey: .showPercentage)
        backgroundStyle = try container.decode(BackgroundStyle.self, forKey: .backgroundStyle)
        isUsingDefaultColor = try container.decode(Bool.self, forKey: .isUsingDefaultColor)
        
        // Try to decode the associated color ID
        if let colorID = try? container.decode(String.self, forKey: .associatedColorID) {
            associatedColorID = colorID
        }
        
        // Decode Color as UIColor components
        let components = try container.decode([CGFloat].self, forKey: .displayColor)
        if components.count == 4 {
            displayColor = Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
        } else {
            displayColor = .white // Default color if decoding fails
        }
        
        // Subscribe to color change notifications
        setupNotificationObserver()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(style.rawValue, forKey: .style)
        try container.encode(showPercentage, forKey: .showPercentage)
        try container.encode(backgroundStyle.rawValue, forKey: .backgroundStyle)
        try container.encode(isUsingDefaultColor, forKey: .isUsingDefaultColor)
        
        // Encode the associated color ID if it exists
        if let colorID = associatedColorID {
            try container.encode(colorID, forKey: .associatedColorID)
        }
        
        // Encode Color as array of components
        if let components = displayColor.cgColor?.components {
            try container.encode(components, forKey: .displayColor)
        } else {
            try container.encode([1.0, 1.0, 1.0, 1.0], forKey: .displayColor) // White color as fallback
        }
    }
    
    func updateColor(for backgroundStyle: BackgroundStyle) {
        // Only update if using default color and this isn't a year tracker
        // (determined by checking if its settings have been saved to UserDefaults)
        let isYearTracker = UserDefaults.standard.object(forKey: "yearTrackerDisplayColorHex") != nil
        
        if isUsingDefaultColor && !isYearTracker {
            // Get the first color from presets as default
            let presets = DisplayColor.getPresets(for: backgroundStyle)
            if let defaultColor = presets.first?.color {
                if displayColor != defaultColor {
                    DispatchQueue.main.async {
                        self.displayColor = defaultColor
                        self.associatedColorID = "orange" // First color is orange
                    }
                }
            }
        }
    }
    
    // Set up observers for color change notifications
    private func setupNotificationObserver() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("DisplayColorChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            // Only update if we have an associated color that matches
            if let userInfo = notification.userInfo,
               let colorID = userInfo["colorID"] as? String,
               let newColor = userInfo["newColor"] as? Color,
               colorID == self.associatedColorID || (self.associatedColorID == nil && self.checkIfUsingStandardColor(colorID)) {
                
                // Update the display color while preserving the isUsingDefaultColor status
                self.displayColor = newColor
                self.associatedColorID = colorID
                
                // Notify anyone observing this object that it changed
                self.objectWillChange.send()
            }
        }
    }
    
    // Check if this display is using a standard color (orange, blue, green) without knowing its ID
    private func checkIfUsingStandardColor(_ colorID: String) -> Bool {
        let currentHex = displayColor.hexString.uppercased()
        
        // Get the reference hexes for comparison
        let referenceHex: String
        switch colorID {
        case "orange":
            referenceHex = UserDefaults.standard.string(forKey: "orangeColorHex") ?? "FF7F00"
        case "blue":
            referenceHex = UserDefaults.standard.string(forKey: "blueColorHex") ?? "008CFF"
        case "green":
            referenceHex = UserDefaults.standard.string(forKey: "greenColorHex") ?? "7FBF54"
        default:
            return false
        }
        
        return currentHex == referenceHex.uppercased()
    }
    
    init(backgroundStyle: BackgroundStyle = .dark) {
        self._id = UUID()
        self.backgroundStyle = backgroundStyle
        // Always set orange as default color
        self.displayColor = Color(hex: "FF7F00") // Default orange
        self.isUsingDefaultColor = true
        self.associatedColorID = "orange"
        
        // Set up notification observer
        setupNotificationObserver()
    }
    
    init() {
        self._id = UUID()
        self.backgroundStyle = .dark
        self.displayColor = Color(hex: "FF7F00")
        self.isUsingDefaultColor = true
        self.associatedColorID = "orange"
        
        // Set up notification observer
        setupNotificationObserver()
    }
    
    deinit {
        // Remove notification observer when this object is deallocated
        NotificationCenter.default.removeObserver(self)
    }
}
