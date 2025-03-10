import SwiftUI

struct TrackEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @ObservedObject var eventStore: EventStore
    @State private var showingLimitAlert = false
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Text("Track Event")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                Form {
                    Section {
                        TextField("Add your event name", text: $eventTitle)
                        DatePicker("Event Date", 
                                 selection: $eventDate,
                                 in: Date()...,
                                 displayedComponents: [.date])
                            .accentColor(Color(hex: "333333"))
                    }
                    
                    Section {
                        Button(action: {
                            // Count user-created events (excluding year tracker)
                            let calendar = Calendar.current
                            let yearString = String(calendar.component(.year, from: Date()))
                            let userEventCount = eventStore.events.filter { $0.title != yearString }.count
                            
                            if userEventCount >= 5 {
                                showingLimitAlert = true
                            } else {
                                let newEvent = Event(title: eventTitle, targetDate: eventDate)
                                eventStore.saveEvent(newEvent)
                                
                                // Find the index of the new event in the displayed events array
                                // Year tracker is always first, so other events start at index 1
                                let yearTracker = eventStore.events.first { $0.title == yearString }
                                let otherEvents = eventStore.events.filter { $0.title != yearString }
                                let displayedEvents = [yearTracker].compactMap { $0 } + otherEvents
                                
                                if let newEventIndex = displayedEvents.firstIndex(where: { $0.id == newEvent.id }) {
                                    // Update the selected tab to navigate to the new event
                                    selectedTab = newEventIndex
                                }
                                
                                dismiss()
                            }
                        }) {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(eventTitle.isEmpty ? Color.gray : Color(hex: "333333"))
                                .cornerRadius(10)
                        }
                        .disabled(eventTitle.isEmpty)
                    }
                }
            }
            .alert("Event Limit Reached", isPresented: $showingLimitAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("You can track up to 5 events at a time (plus the year tracker). Please remove an existing event to add a new one.")
            }
        }
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
    }
}
