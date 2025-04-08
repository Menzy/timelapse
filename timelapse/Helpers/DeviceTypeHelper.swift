import SwiftUI
import UIKit

enum DeviceType {
    case iPhone
    case iPadSmall
    case iPadMedium
    case iPadLarge
    
    // Current device type based on idiom and screen size
    static var current: DeviceType {
        let idiom = UIDevice.current.userInterfaceIdiom
        let screenSize = UIScreen.main.bounds.size
        let maxDimension = max(screenSize.width, screenSize.height)
        
        switch idiom {
        case .pad:
            // Categorize iPads based on screen size
            if maxDimension <= 1024 { // iPad 9th gen, iPad mini
                return .iPadSmall
            } else if maxDimension <= 1180 { // iPad Air, 11" iPad Pro
                return .iPadMedium
            } else { // 12.9" iPad Pro
                return .iPadLarge
            }
        default:
            return .iPhone
        }
    }
    
    // Check if the current device is any iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Get appropriate scale factor for UI elements based on device type
    static var scaleFactor: CGFloat {
        switch current {
        case .iPhone:
            return 1.0
        case .iPadSmall:
            return 1.2
        case .iPadMedium:
            return 1.4
        case .iPadLarge:
            return 1.6
        }
    }
    
    // Get appropriate column count for grid layouts based on device type
    static var gridColumns: Int {
        switch current {
        case .iPhone:
            return 2
        case .iPadSmall:
            return 3
        case .iPadMedium:
            return 4
        case .iPadLarge:
            return 5
        }
    }
    
    // Get appropriate size multiplier for TimeCard based on device type
    static func timeCardWidth(isLandscape: Bool = false) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        
        switch current {
        case .iPhone:
            return screenWidth * 0.76
        case .iPadSmall:
            return screenWidth * 0.60
        case .iPadMedium:
            return screenWidth * 0.55
        case .iPadLarge:
            return screenWidth * 0.50
        }
    }
    
    // Get appropriate height for TimeCard
    static func timeCardHeight(isLandscape: Bool = false) -> CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        
        switch current {
        case .iPhone:
            return screenHeight * 0.45
        case .iPadSmall, .iPadMedium, .iPadLarge:
            return screenHeight * 0.45
        }
    }
}

// Add a modifier to adjust font size based on device type
struct ScaledFont: ViewModifier {
    let name: String
    let size: CGFloat
    
    func body(content: Content) -> some View {
        let scaledSize = size * (DeviceType.isIPad ? DeviceType.scaleFactor : 1.0)
        return content.font(.custom(name, size: scaledSize))
    }
}

extension View {
    func scaledFont(name: String, size: CGFloat) -> some View {
        self.modifier(ScaledFont(name: name, size: size))
    }
} 