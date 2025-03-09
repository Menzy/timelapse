import Foundation
import WidgetKit
import SwiftUI

class SharedDataManager {
    static let shared = SharedDataManager()
    
    // App Group identifier for sharing data with widgets
    private let appGroup = "group.com.wanmenzy.timelapseStorage"
    
    // Keys for storing data
    private let eventsKey = "savedEvents"
    private let displaySettingsKey = "savedDisplaySettings"
    private let yearTrackerInfoKey = "yearTrackerInfo"
    private let widgetPreferencesKey = "widgetPreferences"
    private let lastUpdatedKey = "lastUpdated"
    
    private init() {}
    
    // MARK: - Save Methods
    
    func saveEvents(_ events: [Event]) {
        if let encoded = try? JSONEncoder().encode(events) {
            if let sharedDefaults = UserDefaults(suiteName: appGroup) {
                sharedDefaults.set(encoded, forKey: eventsKey)
                updateLastModified()
            }
            
            // Also save to standard user defaults for backward compatibility
            UserDefaults.standard.set(encoded, forKey: eventsKey)
        }
    }
    
    func saveDisplaySettings(_ settings: [UUID: DisplaySettings]) {
        if let encoded = try? JSONEncoder().encode(settings) {
            if let sharedDefaults = UserDefaults(suiteName: appGroup) {
                sharedDefaults.set(encoded, forKey: displaySettingsKey)
                updateLastModified()
            }
            
            // Also save to standard user defaults for backward compatibility
            UserDefaults.standard.set(encoded, forKey: displaySettingsKey)
        }
    }
    
    func saveYearTrackerInfo(daysLeft: Int, totalDays: Int) {
        let yearInfo: [String: Any] = [
            "daysLeft": daysLeft,
            "totalDays": totalDays,
            "lastUpdated": Date()
        ]
        
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            sharedDefaults.set(yearInfo, forKey: yearTrackerInfoKey)
            updateLastModified()
        }
    }
    
    func saveWidgetPreferences(style: TimeDisplayStyle, 
                              showPercentage: Bool, 
                              backgroundStyle: BackgroundStyle,
                              displayColor: Color?) {
        var widgetPrefs: [String: Any] = [
            "style": style.rawValue,
            "showPercentage": showPercentage,
            "backgroundStyle": backgroundStyle.rawValue
        ]
        
        if let color = displayColor, let cgColor = color.cgColor?.components {
            widgetPrefs["displayColor"] = cgColor
        }
        
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            sharedDefaults.set(widgetPrefs, forKey: widgetPreferencesKey)
            updateLastModified()
        }
    }
    
    // MARK: - Load Methods
    
    func loadEvents() -> [Event]? {
        // Try to load from shared container first
        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let data = sharedDefaults.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            return decoded
        }
        
        // Fall back to regular UserDefaults if needed
        if let data = UserDefaults.standard.data(forKey: eventsKey),
           let decoded = try? JSONDecoder().decode([Event].self, from: data) {
            // Migrate to shared container
            saveEvents(decoded)
            return decoded
        }
        
        return nil
    }
    
    func loadDisplaySettings() -> [UUID: DisplaySettings]? {
        // Try to load from shared container first
        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let data = sharedDefaults.data(forKey: displaySettingsKey),
           let decoded = try? JSONDecoder().decode([UUID: DisplaySettings].self, from: data) {
            return decoded
        }
        
        // Fall back to regular UserDefaults if needed
        if let data = UserDefaults.standard.data(forKey: displaySettingsKey),
           let decoded = try? JSONDecoder().decode([UUID: DisplaySettings].self, from: data) {
            // Migrate to shared container
            saveDisplaySettings(decoded)
            return decoded
        }
        
        return nil
    }
    
    func getYearTrackerInfo() -> (daysLeft: Int, totalDays: Int) {
        // Default values
        var daysLeft = 365
        var totalDays = 365
        
        if let sharedDefaults = UserDefaults(suiteName: appGroup),
           let yearInfo = sharedDefaults.dictionary(forKey: yearTrackerInfoKey) {
            
            daysLeft = yearInfo["daysLeft"] as? Int ?? daysLeft
            totalDays = yearInfo["totalDays"] as? Int ?? totalDays
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
    
    // MARK: - Widget Refresh Methods
    
    private func updateLastModified() {
        // Update the last modified timestamp
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            sharedDefaults.set(Date(), forKey: lastUpdatedKey)
        }
        
        // Refresh widgets immediately
        refreshWidgets()
    }
    
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    func getLastModified() -> Date? {
        if let sharedDefaults = UserDefaults(suiteName: appGroup) {
            return sharedDefaults.object(forKey: lastUpdatedKey) as? Date
        }
        return nil
    }
}