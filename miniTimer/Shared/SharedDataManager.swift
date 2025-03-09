import Foundation
import SwiftUI
import WidgetKit

class SharedDataManager {
    static let shared = SharedDataManager()
    
    // App Group identifier for sharing data with main app
    private let appGroup = "group.com.wanmenzy.timelapseStorage"
    
    // Keys for stored data
    private let eventsKey = "savedEvents"
    private let displaySettingsKey = "savedDisplaySettings"
    private let yearTrackerInfoKey = "yearTrackerInfo"
    private let widgetPreferencesKey = "widgetPreferences"
    private let lastUpdatedKey = "lastUpdated"
    
    private init() {}
    
    // MARK: - Data Access Methods
    
    func getYearTrackerInfo() -> (daysLeft: Int, totalDays: Int) {
        // Default values
        var daysLeft = 365
        var totalDays = 365
        
        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let yearInfo = sharedDefaults.dictionary(forKey: yearTrackerInfoKey) {
            
            daysLeft = yearInfo["daysLeft"] as? Int ?? daysLeft
            totalDays = yearInfo["totalDays"] as? Int ?? totalDays
        } else {
            // Calculate values if not available
            let calendar = Calendar.current
            let today = Date()
            let year = calendar.component(.year, from: today)
            let endOfYear = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
            daysLeft = calendar.dateComponents([.day], from: today, to: endOfYear).day!
        }
        
        return (daysLeft, totalDays)
    }
    
    func getWidgetPreferences() -> (style: String?, showPercentage: Bool, backgroundStyle: String?, displayColor: [CGFloat]?) {
        var style: String?
        var showPercentage = false
        var backgroundStyle: String?
        var displayColor: [CGFloat]?
        
        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let widgetPrefs = sharedDefaults.dictionary(forKey: widgetPreferencesKey) {
            
            style = widgetPrefs["style"] as? String
            showPercentage = widgetPrefs["showPercentage"] as? Bool ?? false
            backgroundStyle = widgetPrefs["backgroundStyle"] as? String
            displayColor = widgetPrefs["displayColor"] as? [CGFloat]
        }
        
        return (style, showPercentage, backgroundStyle, displayColor)
    }
    
    func getLastModified() -> Date? {
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            return sharedDefaults.object(forKey: lastUpdatedKey) as? Date
        }
        return nil
    }
    
    // Convert stored color components to SwiftUI Color
    func colorFromComponents(_ components: [CGFloat]?) -> Color? {
        guard let components = components, components.count >= 4 else {
            return nil
        }
        
        return Color(
            .sRGB,
            red: Double(components[0]),
            green: Double(components[1]),
            blue: Double(components[2]),
            opacity: Double(components[3])
        )
    }
}