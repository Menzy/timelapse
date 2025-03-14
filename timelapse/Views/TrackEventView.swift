import SwiftUI

struct TrackEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var startDate = Date()
    @State private var useCustomStartDate = false
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
                        
                        Toggle("Use Custom Start Date", isOn: $useCustomStartDate)
                        
                        if useCustomStartDate {
                            DatePicker("Start Date",
                                     selection: $startDate,
                                     in: ...eventDate,
                                     displayedComponents: [.date])
                        }
                        
                        DatePicker("End Date", 
                                 selection: $eventDate,
                                 in: Date()...,
                                 displayedComponents: [.date])
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
                                let newEvent = Event(
                                    title: eventTitle,
                                    targetDate: eventDate,
                                    creationDate: useCustomStartDate ? startDate : Date()
                                )
                                eventStore.saveEvent(newEvent)
                                
                                // Find the index of the new event in the displayed events array
                                let yearTracker = eventStore.events.first { $0.title == yearString }
                                let otherEvents = eventStore.events.filter { $0.title != yearString }
                                let displayedEvents = [yearTracker].compactMap { $0 } + otherEvents
                                
                                if let newEventIndex = displayedEvents.firstIndex(where: { $0.id == newEvent.id }) {
                                    selectedTab = newEventIndex
                                }
                                
                                dismiss()
                            }
                        }) {
                            Text("Save")
                                .fontWeight(.semibold)
                                .foregroundColor(eventTitle.isEmpty ? Color.gray : Color.black)
                                .frame(maxWidth: .infinity)
                                .padding()
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
        .presentationDetents([.fraction(0.55)])
        .presentationDragIndicator(.visible)
    }
}
