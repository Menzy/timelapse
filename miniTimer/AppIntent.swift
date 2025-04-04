//
//  AppIntent.swift
//  miniTimer
//
//  Created by Wan Menzy on 2/25/25.
//

import WidgetKit
import AppIntents
import SwiftUI

// Dynamic event provider for widget configuration
struct EventEntity: AppEntity, TypeDisplayRepresentable {
    var id: UUID
    var title: String
    
    static var defaultQuery = EventQuery()
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct EventQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [EventEntity] {
        return identifiers.compactMap { id in
            if let events = loadEvents(), let event = events.first(where: { $0.id == id }) {
                return EventEntity(id: event.id, title: event.title)
            }
            return nil
        }
    }
    
    func suggestedEntities() async throws -> [EventEntity] {
        var entities: [EventEntity] = []
        
        if let events = loadEvents() {
            // Check if user is subscribed
            let isSubscribed = isUserSubscribed()
            
            for event in events {
                // For free users, only add the year tracker event
                if isSubscribed || isYearTracker(event) {
                    entities.append(EventEntity(id: event.id, title: event.title))
                }
            }
        }
        
        // If no events found, add a default one
        if entities.isEmpty {
            let calendar = Calendar.current
            let year = calendar.component(.year, from: Date())
            entities.append(EventEntity(id: UUID(), title: "\(year)"))
        }
        
        return entities
    }
    
    func loadEvents() -> [Event]? {
        if let data = UserDefaults.shared?.data(forKey: "allEvents"),
           let events = try? JSONDecoder().decode([Event].self, from: data) {
            return events
        }
        return nil
    }
    
    // Helper function to check if an event is the year tracker
    private func isYearTracker(_ event: Event) -> Bool {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        return event.title == "\(currentYear)"
    }
    
    // Helper function to check subscription status
    private func isUserSubscribed() -> Bool {
        return UserDefaults.shared?.bool(forKey: "isSubscribed") ?? false
    }
}

// Dynamic color entity for widget configuration
struct ColorEntity: AppEntity, TypeDisplayRepresentable {
    var id: String
    var name: String
    var hexValue: String
    
    static var defaultQuery = ColorQuery()
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Display Color"
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }
}

struct ColorQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ColorEntity] {
        return identifiers.compactMap { colorId in
            let defaultName = colorId.capitalized
            let defaultHex: String
            
            switch colorId {
            case "orange": defaultHex = "FF7F00"
            case "blue": defaultHex = "018AFB"
            case "green": defaultHex = "7FBF54"
            default: defaultHex = "FF7F00"
            }
            
            // Get custom color name and hex if available
            let name = UserDefaults.shared?.string(forKey: "\(colorId)ColorName") ?? defaultName
            let hex = UserDefaults.shared?.string(forKey: "\(colorId)ColorHex") ?? defaultHex
            
            return ColorEntity(id: colorId, name: name, hexValue: hex)
        }
    }
    
    func suggestedEntities() async throws -> [ColorEntity] {
        var entities: [ColorEntity] = []
        let colorIds = ["orange", "blue", "green"]
        
        for colorId in colorIds {
            let defaultName = colorId.capitalized
            let defaultHex: String
            
            switch colorId {
            case "orange": defaultHex = "FF7F00"
            case "blue": defaultHex = "018AFB"
            case "green": defaultHex = "7FBF54"
            default: defaultHex = "FF7F00"
            }
            
            // Get custom color name and hex if available
            let name = UserDefaults.shared?.string(forKey: "\(colorId)ColorName") ?? defaultName
            let hex = UserDefaults.shared?.string(forKey: "\(colorId)ColorHex") ?? defaultHex
            
            entities.append(ColorEntity(id: colorId, name: name, hexValue: hex))
        }
        
        return entities
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your event tracker widget appearance." }
    
    // Primary Display Configuration
    @Parameter(title: "Primary Event", default: nil)
    var selectedEvent: EventEntity?
    
    @Parameter(title: "Display Style", default: .dotPixels)
    var displayStyle: DisplayStyleChoice
    
    @Parameter(title: "Display Color", default: nil)
    var displayColor: ColorEntity?
    
    @Parameter(title: "Background Theme", default: .dark)
    var backgroundTheme: BackgroundChoice
    
    // Secondary Display Configuration (Medium Widget Only)
    @Parameter(title: "Second Event", default: nil)
    var secondaryEvent: EventEntity?
    
    @Parameter(title: "Second Display Style", default: .progressBar)
    var secondaryDisplayStyle: DisplayStyleChoice
    
    @Parameter(title: "Second Display Color", default: nil)
    var secondaryDisplayColor: ColorEntity?
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

enum BackgroundChoice: String, AppEnum {
    case light
    case dark
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Background Theme"
    static var caseDisplayRepresentations: [BackgroundChoice: DisplayRepresentation] = [
        .light: "Light",
        .dark: "Dark"
    ]
}
