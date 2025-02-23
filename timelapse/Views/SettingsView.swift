import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var body: some View {
        NavigationView {
            Form {
                Section("Display") {
                    Toggle("Show All Events in Grid", isOn: $globalSettings.showGridLayout)
                        .onChange(of: globalSettings.showGridLayout) { _, _ in
                            globalSettings.saveSettings()
                        }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SettingsView()
        .environmentObject(GlobalSettings())
}