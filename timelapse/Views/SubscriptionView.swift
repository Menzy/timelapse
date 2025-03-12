import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @StateObject private var paymentManager = PaymentManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Unlock Full Features")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(globalSettings.invertedColor)
                        
                        Text("Create unlimited events and unlock all premium features")
                            .font(.system(size: 16))
                            .foregroundColor(globalSettings.invertedSecondaryColor)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(icon: "infinity", text: "Create unlimited events")
                        FeatureRow(icon: "paintbrush", text: "Customize all display styles")
                        FeatureRow(icon: "bell", text: "Set reminders for your events")
                        FeatureRow(icon: "icloud", text: "Sync across all your devices")
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    
                    // Subscription options
                    if paymentManager.products.isEmpty {
                        ProgressView()
                            .padding()
                    } else {
                        ForEach(paymentManager.products, id: \.id) { product in
                            SubscriptionOptionView(product: product, paymentManager: paymentManager)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Restore purchases button
                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                try await paymentManager.restorePurchases()
                                if paymentManager.isSubscribed {
                                    dismiss()
                                }
                            } catch {
                                errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                                showError = true
                            }
                            isLoading = false
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(globalSettings.invertedSecondaryColor)
                    }
                    .padding(.top, 20)
                    .disabled(isLoading)
                    
                    // Terms and privacy
                    VStack(spacing: 5) {
                        Text("By subscribing, you agree to our")
                            .font(.system(size: 12))
                        
                        HStack(spacing: 5) {
                            Link("Terms of Service", destination: URL(string: "https://www.example.com/terms")!)
                            Text("and")
                            Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(globalSettings.invertedSecondaryColor)
                    .padding(.top, 10)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitle("Premium Subscription", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .onAppear {
            Task {
                await paymentManager.loadProducts()
            }
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var text: String
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Color(hex: "FF7F00"))
                .frame(width: 30, height: 30)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(globalSettings.invertedColor)
            
            Spacer()
        }
    }
}

struct SubscriptionOptionView: View {
    var product: Product
    var paymentManager: PaymentManager
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(globalSettings.invertedColor)
                    
                    Text(product.description)
                        .font(.system(size: 14))
                        .foregroundColor(globalSettings.invertedSecondaryColor)
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(globalSettings.invertedColor)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
            Button(action: {
                Task {
                    isLoading = true
                    do {
                        let success = try await paymentManager.purchase(product)
                        if success {
                            dismiss()
                        }
                    } catch {
                        errorMessage = "Purchase failed: \(error.localizedDescription)"
                        showError = true
                    }
                    isLoading = false
                }
            }) {
                ZStack {
                    Text("Subscribe")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(isLoading ? 0 : 1)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(hex: "FF7F00"))
                .cornerRadius(10)
            }
            .disabled(isLoading)
        }
        .padding(15)
        .background(Color(white: globalSettings.effectiveBackgroundStyle == .light ? 0.95 : 0.15))
        .cornerRadius(15)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(GlobalSettings())
    }
} 