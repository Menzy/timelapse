// EditEventView.swift
import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var eventStore: EventStore
    let event: Event
    @State private var eventTitle: String
    @State private var eventDate: Date
    @State private var showingDeleteAlert = false
    
    init(event: Event, eventStore: EventStore) {
        self.event = event
        self.eventStore = eventStore
        _eventTitle = State(initialValue: event.title)
        _eventDate = State(initialValue: event.targetDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Event Title", text: $eventTitle)
                    DatePicker("Event Date", 
                             selection: $eventDate,
                             in: Date()...,
                             displayedComponents: [.date])
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
                    eventStore.updateEvent(id: event.id, title: eventTitle, targetDate: eventDate)
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