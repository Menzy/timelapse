//
//  AppIntent.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import AppIntents
import SwiftUI

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your year tracker widget appearance." }

    @Parameter(title: "Display Style", default: .dotPixels)
    var displayStyle: DisplayStyleChoice
    
    @Parameter(title: "Display Color", default: .orange)
    var displayColor: ColorChoice
    
    @Parameter(title: "Background Theme", default: .dark)
    var backgroundTheme: BackgroundChoice
}

enum DisplayStyleChoice: String, AppEnum {
    case dotPixels
    case triGrid
    case progressBar
    case countdown
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Display Style"
    static var caseDisplayRepresentations: [DisplayStyleChoice: DisplayRepresentation] = [
        .dotPixels: "DotPixels",
        .triGrid: "TriGrid",
        .progressBar: "ProgressBar",
        .countdown: "Countdown"
    ]
}

enum ColorChoice: String, AppEnum {
    case orange
    case blue
    case green
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Display Color"
    static var caseDisplayRepresentations: [ColorChoice: DisplayRepresentation] = [
        .orange: "Orange",
        .blue: "Blue",
        .green: "Green"
    ]
    
    var color: Color {
        switch self {
        case .orange: return Color(hex: "FF7F00") // Exact orange from main app
        case .blue: return Color(hex: "018AFB")   // Exact blue from main app
        case .green: return Color(hex: "7FBF54")  // Exact green from main app
        }
    }
}

enum BackgroundChoice: String, AppEnum {
    case light
    case dark
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Background Theme"
    static var caseDisplayRepresentations: [BackgroundChoice: DisplayRepresentation] = [
        .light: "Light",
        .dark: "Dark"
    ]
}
