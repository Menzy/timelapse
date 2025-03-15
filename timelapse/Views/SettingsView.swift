import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.openURL) private var openURL
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var showSubscriptionView = false
    @State private var showNotificationSettings = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display") {
                    if paymentManager.isSubscribed {
                        Toggle("Show All Events in Grid", isOn: $globalSettings.showGridLayout)
                            .onChange(of: globalSettings.showGridLayout) { _, _ in
                                globalSettings.saveSettings()
                            }
                    } else {
                        HStack {
                            Text("Show All Events in Grid")
                            Spacer()
                            Button(action: {
                                showSubscriptionView = true
                            }) {
                                Text("Pro")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "FF7F00"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section("Notifications") {
                    if paymentManager.isSubscribed {
                        Button(action: {
                            showNotificationSettings = true
                        }) {
                            HStack {
                                Text("Notification Settings")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        HStack {
                            Text("Notification Settings")
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: {
                                showSubscriptionView = true
                            }) {
                                Text("Pro")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: "FF7F00"))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Section(header: Text("Subscription")) {
                    if paymentManager.isSubscribed {
                        HStack {
                            Text("Premium Subscription")
                                .foregroundColor(.primary)
                            Spacer()
                            Text("Active")
                                .foregroundColor(.green)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    } else {
                        Button(action: {
                            showSubscriptionView = true
                        }) {
                            HStack {
                                Text("Subscribe to Premium")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    if paymentManager.isSubscribed {
                        Button(action: {
                            Task {
                                try? await paymentManager.restorePurchases()
                            }
                        }) {
                            Text("Restore Purchases")
                                .foregroundColor(.primary)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        if let url = URL(string: "https://apps.apple.com/app/id123456789") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Text("Leave a Review")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "star.bubble.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("Privacy Policy")
                    }
                    
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("Terms of Service")
                    }
                    
                    NavigationLink(destination: AboutView()) {
                        Text("About")
                    }
                }
                
                Section {
                    HStack {
                        Text("Version")
                            .foregroundColor(.primary)
                        Spacer()
                        Text(Bundle.main.releaseVersionNumber ?? "1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
            .sheet(isPresented: $showSubscriptionView) {
                SubscriptionView()
                    .environmentObject(globalSettings)
            }
            .sheet(isPresented: $showNotificationSettings) {
                GlobalNotificationSettingsView()
                    .environmentObject(globalSettings)
            }
            .onAppear {
                Task {
                    await paymentManager.updateSubscriptionStatus()
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Privacy Policy")
                    .font(.title.bold())
                    .padding(.bottom, 8)
                
                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .foregroundColor(.secondary)
                
                Text("Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information.")
                
                Group {
                    Text("Information We Collect").font(.headline)
                    Text("We do not collect any personal information. All your data is stored locally on your device.")
                    
                    Text("Data Storage").font(.headline)
                    Text("All event data and preferences are stored locally on your device and are not transmitted to any external servers.")
                }
                
                // Add more privacy policy content as needed
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Terms of Service")
                    .font(.title.bold())
                    .padding(.bottom, 8)
                
                Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                    .foregroundColor(.secondary)
                
                Text("By using our app, you agree to these terms. Please read them carefully.")
                
                Group {
                    Text("1. Acceptance of Terms").font(.headline)
                    Text("By accessing and using this application, you accept and agree to be bound by the terms and provision of this agreement.")
                    
                    Text("2. App License").font(.headline)
                    Text("We grant you a limited, non-exclusive, non-transferable, revocable license to use the app for your personal, non-commercial purposes.")
                }
                
                // Add more terms of service content as needed
            }
            .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image("AppIcon") // Make sure to have this in your assets
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(20)
                    
                    Text("Timelapse")
                        .font(.title2.bold())
                    
                    Text("Version \(Bundle.main.releaseVersionNumber ?? "1.0.0")")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            Section("Creators") {
                HStack {
                    Text("Design & Development")
                    Spacer()
                    Text("Your Name")
                        .foregroundColor(.secondary)
                }
            }
            
            Section("Contact") {
                Button(action: {
                    if let url = URL(string: "mailto:support@yourdomain.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Contact Support")
                }
                
                Button(action: {
                    if let url = URL(string: "https://yourdomain.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Text("Visit Website")
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Extension to get app version
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
}

#Preview {
    SettingsView()
        .environmentObject(GlobalSettings())
}