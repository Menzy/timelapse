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
                    Toggle("Show All Events in Grid", isOn: $globalSettings.showGridLayout)
                        .onChange(of: globalSettings.showGridLayout) { _, _ in
                            globalSettings.saveSettings()
                        }
                }
                
                Section("Notifications") {
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
                    Button(action: {
                        if let url = URL(string: "https://www.wanmenzy.me/privacy-policy") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Text("Privacy Policy")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        if let url = URL(string: "https://www.wanmenzy.me/terms") {
                            openURL(url)
                        }
                    }) {
                        HStack {
                            Text("Terms of Service")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.forward.app")
                                .foregroundColor(.blue)
                        }
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

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image("AppIcon") // Make sure to have this in your assets
                        .resizable()
                        .frame(width: 100, height: 100)
                        .cornerRadius(22)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    
                    Text("Timelapse")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Version \(Bundle.main.releaseVersionNumber ?? "1.0.0")")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            Section("Creators") {
                Button(action: {
                    if let url = URL(string: "https://www.instagram.com/jnrkay") {
                        openURL(url)
                    }
                }) {
                    HStack {
                        Text("Design")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Ed Jnr")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "https://www.instagram.com/menzy.svg") {
                        openURL(url)
                    }
                }) {
                    HStack {
                        Text("Development")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Wan Menzy")
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section("Contact") {
                Button(action: {
                    if let url = URL(string: "mailto:wanmenzy@gmail.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text("Contact Support")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                    }
                }
                
                Button(action: {
                    if let url = URL(string: "https://www.wanmenzy.me/timelapse") {
                        openURL(url)
                    }
                }) {
                    HStack {
                        Text("Visit Website")
                            .foregroundColor(.primary)
                        Spacer()
                        Image(systemName: "globe")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section {
                Text("Thank you for using Timelapse! We hope it helps you keep track of your important dates and events.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 6)
                    .listRowBackground(Color(.systemGroupedBackground))
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