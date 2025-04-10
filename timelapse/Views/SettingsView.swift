import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var paymentManager = PaymentManager.shared
    @State private var showSubscriptionView = false
    @State private var showNotificationSettings = false
    @State private var showResetColorsConfirmation = false
    @State private var showResetThemesConfirmation = false
    @State private var refreshNeeded = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Display Card
                    SettingsCard(title: "Display") {
                        // Show All Events in Grid
                        if paymentManager.isSubscribed {
                            ToggleSettingRow(
                                title: "Show All Events in Grid",
                                isOn: $globalSettings.showGridLayout,
                                onChange: { newValue in
                                    // Add a subtle haptic feedback when toggling
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    
                                    // Use animation to make the toggle feel responsive
                                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                                        globalSettings.showGridLayout = newValue
                                        globalSettings.saveSettings()
                                    }
                                }
                            )
                        } else {
                            PremiumFeatureRow(title: "Show All Events in Grid") {
                                showSubscriptionView = true
                            }
                        }
                        
                        Divider().padding(.horizontal, 12)
                        
                        // App Icon picker
                        if paymentManager.isSubscribed {
                            NavigationSettingRow(
                                title: "App Icon",
                                icon: "app.badge",
                                iconColor: .purple,
                                destination: AnyView(AppIconPickerView())
                            )
                        } else {
                            PremiumFeatureRow(title: "App Icon") {
                                showSubscriptionView = true
                            }
                        }
                        
                        Divider().padding(.horizontal, 12)
                        
                        // Reset Colors
                        if paymentManager.isSubscribed {
                            ActionSettingRow(
                                title: "Reset Display Colors",
                                icon: "arrow.counterclockwise",
                                iconColor: .red
                            ) {
                                showResetColorsConfirmation = true
                            }
                        } else {
                            PremiumFeatureRow(title: "Reset Display Colors") {
                                showSubscriptionView = true
                            }
                        }
                        
                        Divider().padding(.horizontal, 12)
                        
                        // Reset Themes
                        if paymentManager.isSubscribed {
                            ActionSettingRow(
                                title: "Reset Background Themes",
                                icon: "arrow.counterclockwise",
                                iconColor: .orange
                            ) {
                                showResetThemesConfirmation = true
                            }
                        } else {
                            PremiumFeatureRow(title: "Reset Background Themes") {
                                showSubscriptionView = true
                            }
                        }
                    }
                    
                    // Notifications Card
                    SettingsCard(title: "Notifications") {
                        if paymentManager.isSubscribed {
                            ActionSettingRow(
                                title: "Notification Settings",
                                icon: "bell.badge",
                                iconColor: .blue
                            ) {
                                showNotificationSettings = true
                            }
                        } else {
                            PremiumFeatureRow(title: "Notification Settings") {
                                showSubscriptionView = true
                            }
                        }
                    }
                    
                    // Subscription Card
                    SettingsCard(title: "Subscription") {
                        if paymentManager.isSubscribed {
                            HStack {
                                Label {
                                    Text("Premium Subscription")
                                        .foregroundStyle(.primary)
                                } icon: {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundStyle(.green)
                                }
                                
                                Spacer()
                                
                                Text("Active")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            
                            Divider().padding(.horizontal, 12)
                            
                            ActionSettingRow(
                                title: "Restore Purchases",
                                icon: "arrow.clockwise",
                                iconColor: .blue
                            ) {
                                Task {
                                    try? await paymentManager.restorePurchases()
                                }
                            }
                        } else {
                            ActionSettingRow(
                                title: "Subscribe to Premium",
                                icon: "star.fill",
                                iconColor: .yellow
                            ) {
                                showSubscriptionView = true
                            }
                        }
                    }
                    
                    // About Card (with App Info & Legal)
                    SettingsCard(title: "About") {
                        NavigationSettingRow(
                            title: "About Timelapse",
                            icon: "info.circle",
                            iconColor: .teal,
                            destination: AnyView(AboutView())
                        )
                    }
                    
                    // Version info
                    HStack {
                        Spacer()
                        Text("Version \(Bundle.main.releaseVersionNumber ?? "1.0.0")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.top, 5)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
                .padding(.horizontal, 16)
            }
            .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
        .presentationDetents([.large, .medium])
        .presentationDragIndicator(.visible)
    }
}

// Reusable Components for Settings

struct SettingsCard<Content: View>: View {
    var title: String
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
            
            Divider()
                .padding(.horizontal, 12)
            
            content
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct ToggleSettingRow: View {
    var title: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color.blue)
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}

struct ActionSettingRow: View {
    var title: String
    var icon: String
    var iconColor: Color
    var showsChevron: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Label {
                    Text(title)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                
                Spacer()
                
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct NavigationSettingRow<Destination: View>: View {
    var title: String
    var icon: String
    var iconColor: Color
    var destination: Destination
    
    var body: some View {
        NavigationLink {
            destination
        } label: {
            HStack {
                Label {
                    Text(title)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.trailing, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct PremiumFeatureRow: View {
    var title: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
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
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // App Icon and Title Section
                VStack(spacing: 16) {
                    Image(colorScheme == .dark ? "AppIcon-light" : "AppIcon-dark")
                        .resizable()
                        .frame(width: 88, height: 88)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
                    
                    VStack(spacing: 4) {
                        Text("Timelapse")
                            .font(.system(size: 28, weight: .bold))
                            .tracking(-0.5)
                        
                        Text("Version \(Bundle.main.releaseVersionNumber ?? "1.0.0")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                // Creators Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Creators")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "https://www.instagram.com/jnrkay") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Label {
                                Text("Design")
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "paintbrush.pointed")
                                    .foregroundStyle(.purple)
                            }
                            
                            Spacer()
                            
                            Text("Ed Jnr")
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundStyle(.quaternary)
                                .imageScale(.small)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "https://www.instagram.com/menzy.svg") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Label {
                                Text("Development")
                                    .foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: "chevron.left.forwardslash.chevron.right")
                                    .foregroundStyle(.blue)
                            }
                            
                            Spacer()
                            
                            Text("Wan Menzy")
                                .foregroundStyle(.secondary)
                            
                            Image(systemName: "arrow.up.right.circle.fill")
                                .foregroundStyle(.quaternary)
                                .imageScale(.small)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Contact Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Connect")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "mailto:wanmenzy@gmail.com") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Label("Support", systemImage: "envelope.fill")
                                .foregroundStyle(.primary, .indigo)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.trailing, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "https://www.wanmenzy.me/timelapse") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Label("Website", systemImage: "globe")
                                .foregroundStyle(.primary, .teal)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.trailing, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "https://apps.apple.com/app/id123456789") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Label("Rate App", systemImage: "star.fill")
                                .foregroundStyle(.primary, .yellow)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.trailing, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Legal Card
                VStack(alignment: .leading, spacing: 0) {
                    Text("Legal")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "https://www.wanmenzy.me/privacy-policy") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Label("Privacy Policy", systemImage: "lock.shield")
                                .foregroundStyle(.primary, .blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.trailing, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    
                    Divider()
                        .padding(.horizontal, 12)
                    
                    Button {
                        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                            openURL(url)
                        }
                    } label: {
                        HStack {
                            Label("Terms of Use", systemImage: "doc.text")
                                .foregroundStyle(.primary, .blue)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .padding(.trailing, 4)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(UIColor.secondarySystemGroupedBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Thank You Message
                Text("Thank you for using Timelapse! We hope it helps you keep track of your important dates and events.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
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