//
//  timelapseApp.swift
//  timelapse
//
//  Created by Wan Menzy on 2/19/25.
//

import SwiftUI

@main
struct timelapseApp: App {
    @StateObject private var eventStore = EventStore()
    @StateObject private var globalSettings = GlobalSettings()
    
    init() {
        // Set the global accent color
        UIView.appearance().tintColor = UIColor(Color(hex: "333333"))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(globalSettings)
        }
    }
}
