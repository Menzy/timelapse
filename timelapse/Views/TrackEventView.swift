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
        NavigationView {
            VStack(spacing: 20) {
                HStack {        
                    Text("Track Event")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
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
                // .padding(.bottom, 5)
                
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
                            if (!eventStore.canAddMoreEvents()) {
                                showingLimitAlert = true
                            } else {
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
                        }) {
                            Text("Save")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(eventTitle.isEmpty ? .gray : .white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    eventTitle.isEmpty 
                                    ? (colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.5))
                                    : (colorScheme == .dark ? Color(hex: "0B7DD1") : Color(hex: "1A8FEF"))
                                )
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .listRowInsets(EdgeInsets())
                        .disabled(eventTitle.isEmpty)
                    }
                }
            }
            .alert("Event Limit Reached", isPresented: $showingLimitAlert) {
                Button("Subscribe", role: .none) {
                    showSubscriptionView = true
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Free users can create only 1 custom event in addition to the year tracker. Upgrade to TimeLapse Pro to create up to 5 custom events.")
            }
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView()
            }
        }
        .presentationDetents([.fraction(0.5)])
        .presentationDragIndicator(.visible)
        .onAppear {
            Task {
                await paymentManager.updateSubscriptionStatus()
            }
        }
    }
}
