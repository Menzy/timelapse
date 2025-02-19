import SwiftUI

struct TrackEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @ObservedObject var eventStore: EventStore
    
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
            }
            .navigationTitle("Track Event")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button("Save") {
                    let newEvent = Event(title: eventTitle, targetDate: eventDate)
                    eventStore.saveEvent(newEvent)
                    dismiss()
                }
                .disabled(eventTitle.isEmpty)
            )
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}
