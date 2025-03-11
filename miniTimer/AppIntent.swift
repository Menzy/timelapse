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
            for event in events {
                entities.append(EventEntity(id: event.id, title: event.title))
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
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure your event tracker widget appearance." }
    
    // Primary Display Configuration
    @Parameter(title: "Primary Event", default: nil)
    var selectedEvent: EventEntity?
    
    @Parameter(title: "Display Style", default: .dotPixels)
    var displayStyle: DisplayStyleChoice
    
    @Parameter(title: "Display Color", default: .orange)
    var displayColor: ColorChoice
    
    @Parameter(title: "Background Theme", default: .dark)
    var backgroundTheme: BackgroundChoice
    
    // Secondary Display Configuration (Medium Widget Only)
    @Parameter(title: "Second Event", default: nil)
    var secondaryEvent: EventEntity?
    
    @Parameter(title: "Second Display Style", default: .progressBar)
    var secondaryDisplayStyle: DisplayStyleChoice
    
    @Parameter(title: "Second Display Color", default: .blue)
    var secondaryDisplayColor: ColorChoice
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
