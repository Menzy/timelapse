//
//  GlobalSettings.swift
//  timelapse
//
//  Created by Wan Menzy on 2/18/25.
//


import SwiftUI

class GlobalSettings: ObservableObject {
    @Published var backgroundStyle: BackgroundStyle = .light
    @Published var showGridLayout: Bool = false
    @Published private var systemIsDark: Bool = false
    
    init() {
        // Load saved background style from UserDefaults
        if let savedStyle = UserDefaults.standard.string(forKey: "backgroundStyle"),
           let style = BackgroundStyle(rawValue: savedStyle) {
            backgroundStyle = style
        }
        
        // Load grid layout preference
        showGridLayout = UserDefaults.standard.bool(forKey: "showGridLayout")
    }
    
    var effectiveBackgroundStyle: BackgroundStyle {
        if backgroundStyle == .device {
            return systemIsDark ? .dark : .light
        }
        return backgroundStyle
    }
    
    var invertedColor: Color {
        effectiveBackgroundStyle == .light ? Color.black : Color.white
    }
    
    var invertedSecondaryColor: Color {
        effectiveBackgroundStyle == .light ? Color.gray : Color(white: 0.5)
    }
    
    func updateSystemAppearance(_ isDark: Bool) {
        systemIsDark = isDark
        objectWillChange.send()
    }
}

// Extension to handle persistence
extension GlobalSettings {
    func saveSettings() {
        UserDefaults.standard.set(backgroundStyle.rawValue, forKey: "backgroundStyle")
        UserDefaults.standard.set(showGridLayout, forKey: "showGridLayout")
    }
}
