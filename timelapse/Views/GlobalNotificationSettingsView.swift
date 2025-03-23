import SwiftUI

struct GlobalNotificationSettingsView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    @StateObject private var paymentManager = PaymentManager.shared
    
    var body: some View {
        NavigationView {
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
                    } else if authorizationStatus == .authorized {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Notifications are enabled")
                                .foregroundColor(.green)
                        }
                    } else if authorizationStatus == .notDetermined {
                        Button("Enable Notifications") {
                            requestPermissions()
                        }
                        .foregroundColor(.blue)
                    }
                } header: {
                    Text("Notification Status")
                }
                
                // Default notification settings
                Section {
                    DatePicker("Default Time", selection: $globalSettings.defaultNotificationTime, displayedComponents: .hourAndMinute)
                    
                    Picker("Default Frequency", selection: $globalSettings.defaultNotificationFrequency) {
                        ForEach(NotificationFrequency.allCases) { frequency in
                            if frequency != .custom {
                                Text(frequency.rawValue).tag(frequency)
                            }
                        }
                    }
                } header: {
                    Text("Default Settings")
                } footer: {
                    Text("These settings will be used as defaults when creating new events.")
                }
                
                // Year tracker section
                Section {
                    NavigationLink(destination: YearTrackerNotificationsView()) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.blue)
                            Text("Year Tracker Notifications")
                        }
                    }
                } header: {
                    Text("Year Tracker")
                } footer: {
                    Text("Configure special notifications for the year tracker.")
                }
                
                // Manage all notifications
                Section {
                    Button(action: {
                        NotificationManager.shared.removeAllNotifications()
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.red)
                            Text("Remove All Notifications")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Manage Notifications")
                } footer: {
                    Text("This will remove all scheduled notifications for all events.")
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        globalSettings.saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkAuthorizationStatus()
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        globalSettings.checkNotificationAuthorizationStatus { status in
            authorizationStatus = status
        }
    }
    
    private func requestPermissions() {
        globalSettings.requestNotificationPermissions { granted in
            checkAuthorizationStatus()
        }
    }
}

struct YearTrackerNotificationsView: View {
    @EnvironmentObject var eventStore: EventStore
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var yearTrackerEvent: Event?
    @State private var notificationSettings: NotificationSettings = NotificationSettings()
    @State private var isSaving: Bool = false
    @State private var hasChanges: Bool = false
    
    var body: some View {
        ZStack {
            List {
                Section {
                    Toggle("Enable Milestone Notifications", isOn: $notificationSettings.milestoneNotificationsEnabled)
                    
                    if notificationSettings.milestoneNotificationsEnabled {
                        DatePicker("Notification Time", selection: $notificationSettings.notifyTime, displayedComponents: .hourAndMinute)
                        
                        // Special year milestones
                        Toggle("Halfway through the year (July 2)", isOn: Binding(
                            get: { notificationSettings.daysLeftMilestones.contains(183) },
                            set: { newValue in
                                if newValue {
                                    if !notificationSettings.daysLeftMilestones.contains(183) {
                                        notificationSettings.daysLeftMilestones.append(183)
                                    }
                                } else {
                                    notificationSettings.daysLeftMilestones.removeAll { $0 == 183 }
                                }
                            }
                        ))
                        
                        Toggle("100 days left (Sep 22)", isOn: Binding(
                            get: { notificationSettings.daysLeftMilestones.contains(100) },
                            set: { newValue in
                                if newValue {
                                    if !notificationSettings.daysLeftMilestones.contains(100) {
                                        notificationSettings.daysLeftMilestones.append(100)
                                    }
                                } else {
                                    notificationSettings.daysLeftMilestones.removeAll { $0 == 100 }
                                }
                            }
                        ))
                        
                        Toggle("Last quarter (Oct 1)", isOn: Binding(
                            get: { notificationSettings.daysLeftMilestones.contains(92) },
                            set: { newValue in
                                if newValue {
                                    if !notificationSettings.daysLeftMilestones.contains(92) {
                                        notificationSettings.daysLeftMilestones.append(92)
                                    }
                                } else {
                                    notificationSettings.daysLeftMilestones.removeAll { $0 == 92 }
                                }
                            }
                        ))
                        
                        Toggle("30 days left (Dec 1)", isOn: Binding(
                            get: { notificationSettings.daysLeftMilestones.contains(30) },
                            set: { newValue in
                                if newValue {
                                    if !notificationSettings.daysLeftMilestones.contains(30) {
                                        notificationSettings.daysLeftMilestones.append(30)
                                    }
                                } else {
                                    notificationSettings.daysLeftMilestones.removeAll { $0 == 30 }
                                }
                            }
                        ))
                        
                        Toggle("Last week (Dec 24)", isOn: Binding(
                            get: { notificationSettings.daysLeftMilestones.contains(7) },
                            set: { newValue in
                                if newValue {
                                    if !notificationSettings.daysLeftMilestones.contains(7) {
                                        notificationSettings.daysLeftMilestones.append(7)
                                    }
                                } else {
                                    notificationSettings.daysLeftMilestones.removeAll { $0 == 7 }
                                }
                            }
                        ))
                    }
                } header: {
                    Text("Year Milestones")
                } footer: {
                    Text("You'll receive notifications for these important milestones throughout the year.")
                }
                
                Section {
                    Button(action: {
                        isSaving = true
                        saveSettings()
                        hasChanges = false
                        
                        // Automatically dismiss
                        dismiss()
                    }) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .padding(.trailing, 8)
                            }
                            Text(isSaving ? "Saving..." : "Save Settings")
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(isSaving ? .gray : .blue)
                    }
                    .disabled(isSaving || !hasChanges)
                }
            }
            .navigationTitle("Year Tracker Notifications")
            .navigationBarItems(trailing: Button("Done") {
                if hasChanges {
                    // If there are unsaved changes, save them before dismissing
                    saveSettings()
                }
                dismiss()
            })
        }
        .onAppear {
            loadYearTrackerEvent()
        }
        .onChange(of: notificationSettings) { _, _ in
            hasChanges = true
        }
        .onDisappear {
            // Save settings when view disappears if there are changes
            if hasChanges {
                saveSettings()
            }
        }
    }
    
    private func loadYearTrackerEvent() {
        // Find the year tracker event
        let currentYear = String(Calendar.current.component(.year, from: Date()))
        if let yearEvent = eventStore.events.first(where: { $0.title == currentYear }) {
            yearTrackerEvent = yearEvent
            
            // Load saved notification settings
            let savedSettings = eventStore.getNotificationSettings(for: yearEvent.id)
            notificationSettings = savedSettings
            
            // Set milestone type to days left for year tracker if not already set
            if notificationSettings.milestoneType != .daysLeft {
                notificationSettings.milestoneType = .daysLeft
            }
            
            // Only add default milestones if the array is empty
            if notificationSettings.daysLeftMilestones.isEmpty {
                notificationSettings.daysLeftMilestones = [183, 100, 92, 30, 7]
            }
            
            // Reset the hasChanges flag since we just loaded the settings
            hasChanges = false
        } else {
            // Create a default year tracker if it doesn't exist
            let defaultYearTracker = Event.defaultYearTracker()
            eventStore.saveEvent(defaultYearTracker)
            yearTrackerEvent = defaultYearTracker
            
            // Initialize with default settings
            notificationSettings = NotificationSettings()
            notificationSettings.milestoneType = .daysLeft
            notificationSettings.daysLeftMilestones = [183, 100, 92, 30, 7]
            
            // Save these default settings
            if let event = yearTrackerEvent {
                eventStore.updateNotificationSettings(for: event.id, settings: notificationSettings)
            }
            
            // Reset the hasChanges flag
            hasChanges = false
        }
    }
    
    private func saveSettings() {
        if let yearEvent = yearTrackerEvent {
            // Ensure milestone type is set to days left for year tracker
            notificationSettings.milestoneType = .daysLeft
            
            // Update notification settings
            eventStore.updateNotificationSettings(for: yearEvent.id, settings: notificationSettings)
            
            // Request notification permissions if needed
            if notificationSettings.milestoneNotificationsEnabled {
                globalSettings.checkNotificationAuthorizationStatus { status in
                    if status == .notDetermined {
                        globalSettings.requestNotificationPermissions { _ in }
                    }
                }
            }
            
            // Reset the hasChanges flag
            hasChanges = false
            
            // Print debug info
            print("Saved notification settings for Year Tracker: \(notificationSettings)")
        } else {
            print("Error: Could not save notification settings - Year Tracker event not found")
        }
    }
}

struct GlobalNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalNotificationSettingsView()
            .environmentObject(GlobalSettings())
    }
} 