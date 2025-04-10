import SwiftUI

struct TrackEventView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @State private var startDate = Date()
    @State private var useCustomStartDate = false
    @ObservedObject var eventStore: EventStore
    @State private var showingLimitAlert = false
    @State private var showSubscriptionView = false
    @Binding var selectedTab: Int
    @StateObject private var paymentManager = PaymentManager.shared
    
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
                    .padding(.vertical, 4)
                    
                    Toggle(isOn: $useCustomStartDate) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use custom start date")
                                .font(.body)
                            
                            if !useCustomStartDate {
                                Text("Event will start from today")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                    .toggleStyle(.switch)
                    
                    if useCustomStartDate {
                        HStack {
                            Text("Start date")
                                .font(.body)
                            
                            Spacer()
                            
                            DatePicker("", selection: $startDate, in: ...min(Date(), eventDate), displayedComponents: [.date])
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .onChange(of: startDate) { oldValue, newValue in
                                    // Ensure startDate is not after eventDate
                                    if newValue > eventDate {
                                        startDate = eventDate
                                    }
                                }
                        }
                        .padding(.vertical, 4)
                    }
                    
                    HStack {
                        Text("End date")
                            .font(.body)
                        
                        Spacer()
                        
                        DatePicker("", selection: $eventDate, in: Date()..., displayedComponents: [.date])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Event details")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Section {
                    Button {
                        saveEvent()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Create Event", systemImage: "plus.circle")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.medium)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderless)
                    .padding(.vertical, 8)
                    .disabled(eventTitle.isEmpty)
                } header: {
                    Text("Action")
                        .textCase(.uppercase)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Track Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.medium)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .alert("Event Limit Reached", isPresented: $showingLimitAlert) {
                Button("Subscribe", role: .none) {
                    showSubscriptionView = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Free users can create only 1 custom event in addition to the year tracker. Upgrade to TimeLapse Pro to create up to 5 custom events.")
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView()
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            Task {
                await paymentManager.updateSubscriptionStatus()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SubscriptionStatusChanged"))) { _ in
            // Refresh the view to update based on subscription status
            Task {
                await paymentManager.updateSubscriptionStatus()
            }
        }
    }
    
    private func saveEvent() {
        if (!eventStore.canAddMoreEvents()) {
            showingLimitAlert = true
            return
        }
        
        let newEvent = Event(
            title: eventTitle,
            targetDate: eventDate,
            creationDate: useCustomStartDate ? startDate : Date()
        )
        eventStore.saveEvent(newEvent)
        
        // Find the index of the new event in the displayed events array
        let calendar = Calendar.current
        let yearString = String(calendar.component(.year, from: Date()))
        let yearTracker = eventStore.events.first { $0.title == yearString }
        let otherEvents = eventStore.events.filter { $0.title != yearString }
        let displayedEvents = [yearTracker].compactMap { $0 } + otherEvents
        
        if let newEventIndex = displayedEvents.firstIndex(where: { $0.id == newEvent.id }) {
            selectedTab = newEventIndex
        }
        
        dismiss()
    }
}
