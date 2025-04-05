import SwiftUI

struct NotificationSettingsView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    
    let event: Event
    let eventStore: EventStore
    let isYearTracker: Bool
    @State private var notificationSettings: NotificationSettings
    @State private var showTimePicker: Bool = false
    @State private var showCustomDaysPicker: Bool = false
    @State private var showMilestoneEditor: Bool = false
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @State private var hasChanges: Bool = false
    @StateObject private var paymentManager = PaymentManager.shared
    
    init(event: Event, eventStore: EventStore, isYearTracker: Bool = false) {
        self.event = event
        self.eventStore = eventStore
        self.isYearTracker = isYearTracker
        _notificationSettings = State(initialValue: eventStore.getNotificationSettings(for: event.id))
    }
    
    var body: some View {
        NavigationView {
            if !paymentManager.isSubscribed {
                // Show premium upgrade screen
                VStack(spacing: 20) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.yellow)
                        .padding(.bottom, 20)
                    
                    Text("Premium Feature")
                        .font(.title2.bold())
                        .padding(.bottom, 5)
                    
                    Text("Notification settings are available for premium subscribers only.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .foregroundColor(.secondary)
                    
                    Button("Upgrade to Premium") {
                        dismiss()
                        // Post notification to show subscription view
                        NotificationCenter.default.post(name: NSNotification.Name("ShowSubscriptionView"), object: nil)
                    }
                    .padding()
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .padding(.top, 10)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(UIColor.systemGroupedBackground))
                .navigationTitle("Notification Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            } else {
                // Show normal notification settings for premium users
                List {
                    // Authorization status section
                    Section {
                        if authorizationStatus == .denied {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notifications are disabled")
                                    .font(.headline)
                                    .foregroundColor(.red)
                                
                                Text("Please enable notifications for this app in your device settings to receive reminders.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button("Open Settings") {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Enable notifications toggle
                    Section {
                        Toggle("Enable Notifications", isOn: $notificationSettings.isEnabled)
                            .onChange(of: notificationSettings.isEnabled) { oldValue, newValue in
                                if newValue && authorizationStatus == .notDetermined {
                                    globalSettings.requestNotificationPermissions { granted in
                                        if !granted {
                                            notificationSettings.isEnabled = false
                                        }
                                        checkAuthorizationStatus()
                                    }
                                }
                            }
                    } header: {
                        Text("Notification Status")
                    }
                    
                    if notificationSettings.isEnabled {
                        // Frequency section
                        Section {
                            Picker("Frequency", selection: $notificationSettings.frequency) {
                                ForEach(NotificationFrequency.allCases) { frequency in
                                    Text(frequency.rawValue).tag(frequency)
                                }
                            }
                            .pickerStyle(NavigationLinkPickerStyle())
                            
                            if notificationSettings.frequency == .custom {
                                HStack {
                                    Text("Every")
                                    Spacer()
                                    Text("\(notificationSettings.customDays) days")
                                        .foregroundColor(.secondary)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    showCustomDaysPicker = true
                                }
                            }
                            
                            HStack {
                                Text("Time")
                                Spacer()
                                Text(notificationSettings.notifyTime, style: .time)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showTimePicker = true
                            }
                        } header: {
                            Text("Regular Notifications")
                        } footer: {
                            Text("You'll receive notifications about this event at the specified frequency.")
                        }
                        
                        // Milestone notifications section
                        Section {
                            Toggle("Enable Milestone Notifications", isOn: $notificationSettings.milestoneNotificationsEnabled)
                            
                            if notificationSettings.milestoneNotificationsEnabled {
                                Picker("Milestone Type", selection: $notificationSettings.milestoneType) {
                                    ForEach(MilestoneType.allCases) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding(.vertical, 8)
                                
                                NavigationLink(destination: MilestoneEditorView(settings: $notificationSettings)) {
                                    HStack {
                                        Text("Edit Milestones")
                                        Spacer()
                                        Text(milestoneSummary)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        } header: {
                            Text("Milestone Notifications")
                        } footer: {
                            if isYearTracker {
                                Text("You'll receive special notifications for important milestones throughout the year.")
                            } else {
                                Text("You'll receive notifications when you reach important milestones for this event.")
                            }
                        }
                    }
                }
                .navigationTitle(isYearTracker ? "Year Tracker Notifications" : "Notification Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Save") {
                            saveSettings()
                            hasChanges = false
                            
                            // Automatically dismiss after saving
                            dismiss()
                        }
                        .disabled(!hasChanges)
                    }
                }
                .sheet(isPresented: $showTimePicker) {
                    TimePickerView(selectedTime: $notificationSettings.notifyTime)
                }
                .sheet(isPresented: $showCustomDaysPicker) {
                    CustomDaysPickerView(days: $notificationSettings.customDays)
                }
                .onAppear {
                    checkAuthorizationStatus()
                    
                    // For Year Tracker, automatically enable milestone notifications if not already enabled
                    if isYearTracker && !notificationSettings.milestoneNotificationsEnabled {
                        // Only set if not already set to avoid unnecessary state changes
                        notificationSettings.milestoneNotificationsEnabled = true
                        // Ensure the milestone type is set to days left for the year tracker
                        notificationSettings.milestoneType = .daysLeft
                        // Add default milestone days if empty
                        if notificationSettings.daysLeftMilestones.isEmpty {
                            notificationSettings.daysLeftMilestones = [183, 100, 92, 30, 7]
                        }
                        print("Year Tracker: Automatically enabled milestone notifications")
                    }
                }
                .onChange(of: notificationSettings) { _, _ in
                    hasChanges = true
                }
            }
        }
    }
    
    private var milestoneSummary: String {
        switch notificationSettings.milestoneType {
        case .percentage:
            return "\(notificationSettings.percentageMilestones.count) milestones"
        case .daysLeft:
            return "\(notificationSettings.daysLeftMilestones.count) milestones"
        case .specificDate:
            return "\(notificationSettings.specificDateMilestones.count) dates"
        }
    }
    
    private func checkAuthorizationStatus() {
        globalSettings.checkNotificationAuthorizationStatus { status in
            authorizationStatus = status
        }
    }
    
    private func saveSettings() {
        print("Saving notification settings for event ID: \(event.id)")
        print("Settings before save: isEnabled = \(notificationSettings.isEnabled), frequency = \(notificationSettings.frequency.rawValue)")
        
        // Make sure to update the EventStore with our changes
        eventStore.updateNotificationSettings(for: event.id, settings: notificationSettings)
        
        // Force a save to UserDefaults to ensure persistence
        eventStore.saveNotificationSettings()
        
        // For year tracker, verify special milestone settings
        if isYearTracker {
            // Always force days left milestone type for year tracker
            if notificationSettings.milestoneType != .daysLeft {
                notificationSettings.milestoneType = .daysLeft
                eventStore.updateNotificationSettings(for: event.id, settings: notificationSettings)
                eventStore.saveNotificationSettings()
            }
            
            // Schedule year tracker milestones if enabled
            if notificationSettings.milestoneNotificationsEnabled {
                NotificationManager.shared.scheduleYearTrackerMilestones(for: event, with: notificationSettings)
            }
        }
        
        hasChanges = false
        print("Notification settings saved successfully for \(event.title): \(notificationSettings)")
        
        // Verify that the settings were saved properly
        let verifySettings = eventStore.getNotificationSettings(for: event.id)
        print("Verification after save - isEnabled: \(verifySettings.isEnabled), frequency: \(verifySettings.frequency.rawValue)")
    }
}

struct TimePickerView: View {
    @Binding var selectedTime: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                    .labelsHidden()
            }
            .navigationTitle("Select Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CustomDaysPickerView: View {
    @Binding var days: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Days", selection: $days) {
                    ForEach(1...30, id: \.self) { day in
                        Text("\(day) \(day == 1 ? "day" : "days")").tag(day)
                    }
                }
                .pickerStyle(WheelPickerStyle())
            }
            .navigationTitle("Custom Frequency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct MilestoneEditorView: View {
    @Binding var settings: NotificationSettings
    @State private var newDaysLeft: String = ""
    @State private var newPercentage: String = ""
    @State private var newDate: Date = Date()
    @State private var showDatePicker: Bool = false
    
    var body: some View {
        List {
            Section {
                switch settings.milestoneType {
                case .percentage:
                    ForEach(settings.percentageMilestones.sorted(), id: \.self) { percentage in
                        HStack {
                            Text("\(percentage)%")
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        let sortedMilestones = settings.percentageMilestones.sorted()
                        let indicesToRemove = indexSet.map { sortedMilestones[$0] }
                        settings.percentageMilestones.removeAll { indicesToRemove.contains($0) }
                    }
                    
                    HStack {
                        TextField("Add percentage", text: $newPercentage)
                            .keyboardType(.numberPad)
                        
                        Button(action: addPercentageMilestone) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                case .daysLeft:
                    ForEach(settings.daysLeftMilestones.sorted(), id: \.self) { days in
                        HStack {
                            Text("\(days) days left")
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        let sortedMilestones = settings.daysLeftMilestones.sorted()
                        let indicesToRemove = indexSet.map { sortedMilestones[$0] }
                        settings.daysLeftMilestones.removeAll { indicesToRemove.contains($0) }
                    }
                    
                    HStack {
                        TextField("Add days", text: $newDaysLeft)
                            .keyboardType(.numberPad)
                        
                        Button(action: addDaysLeftMilestone) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    
                case .specificDate:
                    ForEach(settings.specificDateMilestones.indices, id: \.self) { index in
                        HStack {
                            Text(settings.specificDateMilestones[index], style: .date)
                            Spacer()
                        }
                    }
                    .onDelete { indexSet in
                        settings.specificDateMilestones.remove(atOffsets: indexSet)
                    }
                    
                    Button(action: {
                        showDatePicker = true
                    }) {
                        HStack {
                            Image(systemName: "calendar")
                            Text("Add Date")
                        }
                    }
                }
            } header: {
                Text("Milestones")
            } footer: {
                switch settings.milestoneType {
                case .percentage:
                    Text("You'll be notified when you reach these percentage milestones.")
                case .daysLeft:
                    Text("You'll be notified when these many days are left.")
                case .specificDate:
                    Text("You'll be notified on these specific dates.")
                }
            }
            
            if settings.milestoneType == .percentage {
                Section {
                    Button("Reset to Default") {
                        settings.percentageMilestones = [25, 50, 75, 90]
                    }
                }
            } else if settings.milestoneType == .daysLeft {
                Section {
                    Button("Reset to Default") {
                        settings.daysLeftMilestones = [100, 30, 14, 7, 3, 1]
                    }
                }
            }
        }
        .navigationTitle("Edit Milestones")
        .sheet(isPresented: $showDatePicker) {
            DatePickerView(selectedDate: $newDate, onSave: addDateMilestone)
        }
    }
    
    private func addPercentageMilestone() {
        guard let percentage = Int(newPercentage), percentage > 0, percentage <= 100 else {
            return
        }
        
        if !settings.percentageMilestones.contains(percentage) {
            settings.percentageMilestones.append(percentage)
        }
        
        newPercentage = ""
    }
    
    private func addDaysLeftMilestone() {
        guard let days = Int(newDaysLeft), days > 0 else {
            return
        }
        
        if !settings.daysLeftMilestones.contains(days) {
            settings.daysLeftMilestones.append(days)
        }
        
        newDaysLeft = ""
    }
    
    private func addDateMilestone() {
        if !settings.specificDateMilestones.contains(where: { Calendar.current.isDate($0, inSameDayAs: newDate) }) {
            settings.specificDateMilestones.append(newDate)
        }
        
        showDatePicker = false
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss
    let onSave: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .labelsHidden()
                    .padding()
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct NotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let eventStore = EventStore()
        let event = Event.defaultYearTracker()
        
        return NotificationSettingsView(event: event, eventStore: eventStore)
            .environmentObject(GlobalSettings())
            .environmentObject(eventStore)
    }
} 