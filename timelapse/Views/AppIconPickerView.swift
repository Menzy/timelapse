import SwiftUI

struct AppIconPickerView: View {
    @StateObject private var iconManager = AppIconManager()
    @StateObject private var paymentManager = PaymentManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showSubscriptionView = false
    
    var body: some View {
        ZStack {
            // Background color to match Form background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Subtitle
                Text("Choose your Vibe")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                
                // Horizontal icon arrangement
                HStack(spacing: 24) {
                    ForEach(AppIconType.allCases) { iconType in
                        Button(action: {
                            // Check if user is subscribed before allowing icon change
                            if paymentManager.isSubscribed {
                                iconManager.changeAppIcon(to: iconType)
                            } else {
                                // Show subscription view for non-subscribers
                                showSubscriptionView = true
                            }
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                // App icon preview
                                Image(iconType.previewImageName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(16)
                                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(iconManager.currentIcon == iconType ? Color.blue : Color.clear, lineWidth: 3)
                                    )
                                
                                // Selected indicator
                                if iconManager.currentIcon == iconType {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 24, weight: .bold))
                                        .background(Circle().fill(Color.white))
                                        .offset(x: 6, y: 6)
                                }
                            }
                            .padding(4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button("Done") {
            dismiss()
        })
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionView()
        }
        .onAppear {
            Task {
                await paymentManager.updateSubscriptionStatus()
            }
        }
    }
}

#Preview {
    NavigationView {
        AppIconPickerView()
    }
} 