import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @StateObject private var paymentManager = PaymentManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Separate products by type
    private var lifetimeProduct: Product? {
        paymentManager.products.first(where: { $0.id == ProductType.lifetime.rawValue })
    }
    
    private var subscriptionProducts: [Product] {
        let products = paymentManager.products.filter { 
            $0.id == ProductType.monthlySubscription.rawValue || 
            $0.id == ProductType.yearlySubscription.rawValue 
        }
        
        // Sort to ensure yearly is after monthly for display
        return products.sorted { first, second in
            // Sort yearly subscription after monthly
            if first.id == ProductType.monthlySubscription.rawValue {
                return true
            } else {
                return false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Upgrade to TimeLapse Pro")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color.primary)          
                        Text("Master your time with ease")
                            .font(.system(size: 16))
                            .foregroundColor(Color.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 15) {
                        FeatureRow(icon: "calendar.badge.plus", text: "Create and customize up to 5 custom events")
                        FeatureRow(icon: "bell.badge", text: "Personalize notifications for each event")
                        FeatureRow(icon: "square.grid.2x2", text: "View all events in a beautiful, organized grid layout")
                        FeatureRow(icon: "app.badge", text: "Access custom events as interactive widgets")
                        FeatureRow(icon: "paintbrush.fill", text: "Customize event appearance with custom hex colors")
                        FeatureRow(icon: "square.and.arrow.up", text: "Edit, style, and share your events effortlessly")
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    
                    // Subscription options
                    if paymentManager.products.isEmpty {
                        // Use fallback pricing options when products can't be loaded
                        PricingOptionsView(paymentManager: paymentManager)
                    } else {
                        VStack(spacing: 15) {
                            // Subscription header
                            Text("Choose Your Plan")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            // Subscription options
                            ForEach(subscriptionProducts, id: \.id) { product in
                                SubscriptionOptionView(product: product, paymentManager: paymentManager)
                                    .padding(.horizontal)
                            }
                            
                            // Lifetime option header
                            if let lifetimeProduct = lifetimeProduct {
                                Text("Lifetime Access")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 20)
                                    .padding(.horizontal)
                                
                                LifetimeOptionView(product: lifetimeProduct, paymentManager: paymentManager)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    // Restore purchases button
                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                try await paymentManager.restorePurchases()
                                if paymentManager.isSubscribed || paymentManager.hasLifetimePurchase {
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
                            .foregroundColor(Color.white.opacity(0.7))
                    }
                    .padding(.top, 20)
                    .disabled(isLoading)
                    
                    // Terms and privacy
                    VStack(spacing: 5) {
                        Text("By subscribing, you agree to our")
                            .font(.system(size: 12))
                        
                        HStack(spacing: 5) {
                            Link("Terms of Service", destination: URL(string: "https://www.example.com/terms")!)
                                .foregroundColor(Color(hex: "FF7F00"))
                            Text("and")
                            Link("Privacy Policy", destination: URL(string: "https://www.example.com/privacy")!)
                                .foregroundColor(Color(hex: "FF7F00"))
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.white.opacity(0.7))
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
                .foregroundColor(Color.primary)
            
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
    
    var formattedTrialPeriod: String {
        // For our product IDs, we know they have a 7-day free trial
        return "7-day free trial, then"
    }
    
    var savingsText: String? {
        // Only calculate for yearly subscription
        if product.id == ProductType.yearlySubscription.rawValue {
            // Calculate savings - $0.99 * 12 months = $11.88 yearly if paying monthly
            // Yearly is $8.99, so saving $2.89 or ~24%
            return "Save 24% compared to monthly"
        }
        return nil
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(product.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if let savingsText = savingsText {
                            Text(savingsText)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.7))
                        } else {
                            Text(product.description)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.7))
                        }
                        
                        Text(formattedTrialPeriod)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "FF7F00"))
                    }
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.white)
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
        .background(Color(white: 0.17)) // Dark gray card background
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

struct LifetimeOptionView: View {
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
                        .foregroundColor(Color.white)
                    
                    Text("One-time purchase, unlimited access forever")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.7))
                    
                    Text("Pay once, use forever")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "FF7F00"))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                    
                    Text("one time")
                        .font(.system(size: 12))
                        .foregroundColor(Color.white.opacity(0.7))
                }
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
                    Text("Buy Now")
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
        .background(Color(white: 0.17)) // Dark gray card background
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(Color(hex: "FF7F00"), lineWidth: 2)
        )
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct PricingOptionsView: View {
    var paymentManager: PaymentManager
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption: ProductType? = nil
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // Subscription header
            Text("Choose Your Plan")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Monthly option
            PricingButton(
                title: "Monthly Premium",
                subtitle: "7-day free trial, then",
                price: "$0.99/month",
                isSelected: selectedOption == .monthlySubscription,
                isLoading: isLoading && selectedOption == .monthlySubscription,
                action: { 
                    selectedOption = .monthlySubscription
                    handlePurchase(.monthlySubscription)
                }
            )
            .padding(.horizontal)
            
            // Yearly option
            PricingButton(
                title: "Yearly Premium",
                subtitle: "Save 24% compared to monthly",
                price: "$8.99/year",
                additionalInfo: "7-day free trial",
                isSelected: selectedOption == .yearlySubscription,
                isLoading: isLoading && selectedOption == .yearlySubscription,
                action: { 
                    selectedOption = .yearlySubscription
                    handlePurchase(.yearlySubscription)
                }
            )
            .padding(.horizontal)
            
            // Lifetime header
            Text("Lifetime Access")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 10)
                .padding(.horizontal)
            
            // Lifetime option
            PricingButton(
                title: "Lifetime Premium",
                subtitle: "One-time purchase, unlimited access forever",
                price: "$19.99",
                additionalInfo: "Pay once, use forever",
                isSelected: selectedOption == .lifetime,
                isLoading: isLoading && selectedOption == .lifetime,
                action: { 
                    selectedOption = .lifetime
                    handlePurchase(.lifetime)
                }
            )
            .padding(.horizontal)
        }
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handlePurchase(_ productType: ProductType) {
        isLoading = true
        
        Task {
            do {
                // Try loading products again in case they failed initially
                await paymentManager.loadProducts()
                
                // Check if the product is now available
                if let product = paymentManager.products.first(where: { $0.id == productType.rawValue }) {
                    // Attempt to purchase
                    let success = try await paymentManager.purchase(product)
                    if success {
                        await MainActor.run {
                            dismiss()
                        }
                    }
                } else {
                    // Still can't find the product
                    await MainActor.run {
                        errorMessage = "Unable to load the selected product. Please try again later."
                        showError = true
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Purchase failed: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

struct PricingButton: View {
    var title: String
    var subtitle: String
    var price: String
    var additionalInfo: String? = nil
    var isSelected: Bool
    var isLoading: Bool = false
    var action: () -> Void
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var body: some View {
        Button(action: action) {
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.white)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(subtitle)
                                .font(.system(size: 14))
                                .foregroundColor(Color.white.opacity(0.7))
                            
                            if let additionalInfo = additionalInfo {
                                Text(additionalInfo)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(hex: "FF7F00"))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text(price)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.white)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                
                ZStack {
                    Text(title == "Lifetime Premium" ? "Buy Now" : "Subscribe")
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
            .padding(15)
            .background(Color(white: 0.17)) // Dark gray card background
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isSelected ? Color(hex: "FF7F00") : (title == "Lifetime Premium" ? Color(hex: "FF7F00") : Color.clear), lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(GlobalSettings())
    }
} 
