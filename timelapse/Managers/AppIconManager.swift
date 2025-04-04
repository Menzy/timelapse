import SwiftUI

enum AppIconType: String, CaseIterable, Identifiable {
    case primary = "Default"
    case fire = "fire"
    case splick = "splick"
    
    var id: String { rawValue }
    
    var iconName: String? {
        switch self {
        case .primary:
            return nil // nil means use the primary app icon
        case .fire:
            return "fire" // This matches the key in Info.plist
        case .splick:
            return "splick" // This matches the key in Info.plist
        }
    }
    
    var displayName: String {
        switch self {
        case .primary: return "Default"
        case .fire: return "Fire"
        case .splick: return "Splick"
        }
    }
    
    var previewImageName: String {
        switch self {
        case .primary: return "AppIcon-light"
        case .fire: return "fire-light"
        case .splick: return "splick-light"
        }
    }
}

class AppIconManager: ObservableObject {
    @Published var currentIcon: AppIconType = .primary
    
    init() {
        // Determine the current app icon
        if let alternateIconName = UIApplication.shared.alternateIconName {
            currentIcon = AppIconType(rawValue: alternateIconName) ?? .primary
        } else {
            currentIcon = .primary
        }
    }
    
    func changeAppIcon(to iconType: AppIconType) {
        guard UIApplication.shared.supportsAlternateIcons else {
            print("This device does not support alternate icons")
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconType.iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.currentIcon = iconType
                }
            }
        }
    }
} 