import SwiftUI

struct TrackEventView: View {
    @Environment(\.dismiss) var dismiss
    @State private var eventTitle = ""
    @State private var eventDate = Date()
    @ObservedObject var eventStore: EventStore
    
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
                            let newEvent = Event(title: eventTitle, targetDate: eventDate)
                            eventStore.saveEvent(newEvent)
                            dismiss()
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
        }
        .presentationDetents([.fraction(0.45)])
        .presentationDragIndicator(.visible)
    }
}
