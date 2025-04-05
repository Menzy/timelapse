import SwiftUI

struct GlobalNotificationSettingsView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    @StateObject private var paymentManager = PaymentManager.shared
    
    var body: some View {
        NavigationView {
            // Check if user is subscribed
            if !paymentManager.isSubscribed {
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
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            } else {
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

struct GlobalNotificationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalNotificationSettingsView()
            .environmentObject(GlobalSettings())
    }
} 