import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.openURL) private var openURL
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var showSubscriptionView = false
    @State private var showNotificationSettings = false
    @State private var showResetColorsConfirmation = false
    @State private var showResetThemesConfirmation = false
    @State private var refreshNeeded = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display") {
                    if paymentManager.isSubscribed {
                        Toggle("Show All Events in Grid", isOn: $globalSettings.showGridLayout)
                            .onChange(of: globalSettings.showGridLayout) { _, newValue in
                                // Add a subtle haptic feedback when toggling
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                // Use animation to make the toggle feel responsive
                                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                                    globalSettings.showGridLayout = newValue
                                    globalSettings.saveSettings()
                                }
                            }
                            .tint(Color.blue) // Make toggle more visible
                    } else {
                        HStack {
                            Text("Show All Events in Grid")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            // Premium badge
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showSubscriptionView = true
                        }
                    }
                    
                    // App Icon picker is now a premium feature
                    if paymentManager.isSubscribed {
                        NavigationLink(destination: AppIconPickerView()) {
                            HStack {
                                Text("App Icon")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "app.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        HStack {
                            Text("App Icon")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            // Premium badge
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showSubscriptionView = true
                        }
                    }
                    
                    // Reset Colors is now a premium feature
                    if paymentManager.isSubscribed {
                        Button(action: {
                            showResetColorsConfirmation = true
                        }) {
                            HStack {
                                Text("Reset Display Colors")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        HStack {
                            Text("Reset Display Colors")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            // Premium badge
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showSubscriptionView = true
                        }
                    }
                    
                    // Reset Themes is now a premium feature
                    if paymentManager.isSubscribed {
                        Button(action: {
                            showResetThemesConfirmation = true
                        }) {
                            HStack {
                                Text("Reset Background Themes")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.counterclockwise")
                                    .foregroundColor(.blue)
                            }
                        }
                    } else {
                        HStack {
                            Text("Reset Background Themes")
                                .foregroundColor(.primary)
                            Spacer()
                            
                            // Premium badge
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showSubscriptionView = true
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
                            
                            // Premium badge
                            Text("PRO")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.yellow)
                                .foregroundColor(.black)
                                .cornerRadius(4)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            showSubscriptionView = true
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
            .confirmationDialog(
                "Reset Display Colors",
                isPresented: $showResetColorsConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Colors", role: .destructive) {
                    // Reset all colors to defaults
                    DisplayColor.resetAllColorsToDefaults()
                    refreshNeeded = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all display colors to their factory defaults. This action cannot be undone.")
            }
            .onChange(of: refreshNeeded) { _, _ in
                if refreshNeeded {
                    // This forces a refresh after colors are reset
                    refreshNeeded = false
                }
            }
            .confirmationDialog(
                "Reset Background Themes",
                isPresented: $showResetThemesConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset All Themes", role: .destructive) {
                    // Reset all themes to defaults
                    BackgroundStyle.resetAllThemesToDefaults()
                    refreshNeeded = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will reset all customizable background themes (Navy, Fire, Dream) to their factory defaults. This action cannot be undone.")
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(colorScheme == .dark ? "AppIcon-light" : "AppIcon-dark")
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