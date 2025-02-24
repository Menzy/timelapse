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
    
    var backgroundColor: Color {
        switch self {
        case .light:
            return .white
        case .dark:
            return Color(hex: "111111")
        case .navy:
            return Color(hex: "001524")
        case .fire:
            return .black
        case .dream:
            return Color(hex: "002728")
        case .device:
            return Color.primary
        }
    }
}

struct DisplayColor: Identifiable {
    let id = UUID()
    let name: String
    let color: Color
    
    static func getPresets(for backgroundStyle: BackgroundStyle) -> [DisplayColor] {
        return [
            DisplayColor(name: "Orange", color: Color(hex: "FF7F00")),
            DisplayColor(name: "Blue", color: Color(hex: "008CFF")),
            DisplayColor(name: "Green", color: Color(hex: "7FBF54"))
        ]
    }
    
    // Helper to create color from hex
    static func color(hex: String) -> Color {
        Color(hex: hex)
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
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case style
        case showPercentage
        case displayColor
        case backgroundStyle
        case isUsingDefaultColor
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _id = try container.decode(UUID.self, forKey: .id)
        style = try container.decode(TimeDisplayStyle.self, forKey: .style)
        showPercentage = try container.decode(Bool.self, forKey: .showPercentage)
        backgroundStyle = try container.decode(BackgroundStyle.self, forKey: .backgroundStyle)
        isUsingDefaultColor = try container.decode(Bool.self, forKey: .isUsingDefaultColor)
        
        // Decode Color as UIColor components
        let components = try container.decode([CGFloat].self, forKey: .displayColor)
        if components.count == 4 {
            displayColor = Color(red: components[0], green: components[1], blue: components[2], opacity: components[3])
        } else {
            displayColor = .white // Default color if decoding fails
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_id, forKey: .id)
        try container.encode(style.rawValue, forKey: .style)
        try container.encode(showPercentage, forKey: .showPercentage)
        try container.encode(backgroundStyle.rawValue, forKey: .backgroundStyle)
        try container.encode(isUsingDefaultColor, forKey: .isUsingDefaultColor)
        
        // Encode Color as array of components
        if let components = displayColor.cgColor?.components {
            try container.encode(components, forKey: .displayColor)
        } else {
            try container.encode([1.0, 1.0, 1.0, 1.0], forKey: .displayColor) // White color as fallback
        }
    }
    
    func updateColor(for backgroundStyle: BackgroundStyle) {
        // Only update if using default color
        if isUsingDefaultColor {
            let orangeColor = Color(hex: "FF7F00")
            if displayColor != orangeColor {
                DispatchQueue.main.async {
                    self.displayColor = orangeColor
                }
            }
        }
    }
    
    init(backgroundStyle: BackgroundStyle = .dark) {
        self._id = UUID()
        self.backgroundStyle = backgroundStyle
        // Always set orange as default color
        self.displayColor = Color(hex: "FF7F00") // Default orange
        self.isUsingDefaultColor = true
    }
    
    init() {
        self._id = UUID()
        self.backgroundStyle = .dark
        self.displayColor = Color(hex: "FF7F00")
        self.isUsingDefaultColor = true
    }
}
