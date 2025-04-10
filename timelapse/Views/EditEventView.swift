// EditEventView.swift
import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
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
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Event name")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter event title", text: $eventTitle)
                            .font(.headline)
                            .padding(.vertical, 8)
                    }
                    .listRowSeparator(.hidden)
                    .padding(.vertical, 4)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Start date")
                                .font(.body)
                            
                            Spacer()
                            
                            DatePicker("",
                                     selection: $startDate,
                                     in: ...min(Date(), eventDate),
                                     displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .onChange(of: startDate) { oldValue, newValue in
                                // Ensure startDate is not after eventDate
                                if newValue > eventDate {
                                    startDate = eventDate
                                }
                            }
                        }
                        
                        HStack {
                            Text("End date")
                                .font(.body)
                            
                            Spacer()
                            
                            if event.targetDate < Date() {
                                // For overdue events, allow selecting the original date or any future date
                                DatePicker("", 
                                         selection: $eventDate,
                                         in: min(event.targetDate, Date())...,
                                         displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            } else {
                                // For future events, maintain current behavior
                                DatePicker("", 
                                         selection: $eventDate,
                                         in: Date()...,
                                         displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Event details")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Event", systemImage: "trash")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.vertical, 8)
                } header: {
                    Text("Danger zone")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        eventStore.updateEvent(id: event.id, title: eventTitle, targetDate: eventDate, creationDate: startDate)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(eventTitle.isEmpty)
                }
            }
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