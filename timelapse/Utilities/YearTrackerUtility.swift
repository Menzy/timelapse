import SwiftUI
import Combine

// Year Tracker utility functions
enum YearTrackerUtility {
    // Save year tracker settings to a consistent key in UserDefaults
    static func saveSettings(_ settings: DisplaySettings) {
        UserDefaults.standard.set(settings.displayColor.hexString, forKey: "yearTrackerDisplayColorHex")
        UserDefaults.standard.set(settings.showPercentage, forKey: "yearTrackerShowPercentage")
        UserDefaults.standard.set(settings.style.rawValue, forKey: "yearTrackerStyle")
        UserDefaults.standard.set(settings.isUsingDefaultColor, forKey: "yearTrackerIsUsingDefaultColor")
    }
    
    // Load year tracker settings from UserDefaults
    static func loadSettings(into settings: DisplaySettings) {
        if let colorHex = UserDefaults.standard.string(forKey: "yearTrackerDisplayColorHex") {
            settings.displayColor = Color(hex: colorHex)
        }
        
        if UserDefaults.standard.object(forKey: "yearTrackerShowPercentage") != nil {
            settings.showPercentage = UserDefaults.standard.bool(forKey: "yearTrackerShowPercentage")
        }
        
        if let styleRaw = UserDefaults.standard.string(forKey: "yearTrackerStyle"),
           let style = TimeDisplayStyle(rawValue: styleRaw) {
            settings.style = style
        }
        
        if UserDefaults.standard.object(forKey: "yearTrackerIsUsingDefaultColor") != nil {
            settings.isUsingDefaultColor = UserDefaults.standard.bool(forKey: "yearTrackerIsUsingDefaultColor")
        }
    }
    
    // Set up notification observer for year tracker color changes
    static func setupColorChangeObserver(for settings: DisplaySettings, onComplete: @escaping () -> Void) -> AnyCancellable {
        return NotificationCenter.default.publisher(for: Notification.Name("YearTrackerDisplayColorChanged"))
            .compactMap { notification -> Color? in
                guard let userInfo = notification.userInfo,
                      let newColor = userInfo["newColor"] as? Color else { return nil }
                return newColor
            }
            .receive(on: RunLoop.main)
            .sink { newColor in
                settings.displayColor = newColor
                settings.isUsingDefaultColor = false
                onComplete()
            }
    }
    
    // Current year as String
    static var currentYearTitle: String {
        String(Calendar.current.component(.year, from: Date()))
    }
} 