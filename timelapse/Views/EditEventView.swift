// EditEventView.swift
import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var eventStore: EventStore
    let event: Event
    @State private var eventTitle: String
    @State private var eventDate: Date
    @State private var startDate: Date
    @State private var showingDeleteAlert = false
    
    init(event: Event, eventStore: EventStore) {
        self.event = event
        self.eventStore = eventStore
        _eventTitle = State(initialValue: event.title)
        _eventDate = State(initialValue: event.targetDate)
        _startDate = State(initialValue: event.creationDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Title", text: $eventTitle)
                    DatePicker("Start Date",
                             selection: $startDate,
                             in: ...eventDate,
                             displayedComponents: [.date])
                    
                    // For end date, use the original date even if it's in the past
                    if event.targetDate < Date() {
                        // For overdue events, allow selecting the original date or any future date
                        DatePicker("End Date", 
                                 selection: $eventDate,
                                 in: min(event.targetDate, Date())...,
                                 displayedComponents: [.date])
                    } else {
                        // For future events, maintain current behavior
                        DatePicker("End Date", 
                                 selection: $eventDate,
                                 in: Date()...,
                                 displayedComponents: [.date])
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Text("Delete Event")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    eventStore.updateEvent(id: event.id, title: eventTitle, targetDate: eventDate, creationDate: startDate)
                    dismiss()
                }
                .disabled(eventTitle.isEmpty)
            )
            .alert("Delete Event", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    eventStore.deleteEvent(event)
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}