import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @EnvironmentObject var globalSettings: GlobalSettings
    @StateObject private var paymentManager = PaymentManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Theme colors
    private var accentColor: Color { Color(hex: "FF7F00") }
    private var secondaryAccentColor: Color { Color(hex: "FF7F00").opacity(0.8) }
    private var surfaceColor: Color { colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6) }
    
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
                VStack(spacing: 0) {
                    // Header with image
                    VStack(spacing: 24) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 60))
                            .foregroundStyle(accentColor.gradient)
                            .symbolEffect(.pulse)
                            .padding(.top, 24)
                        
                        VStack(spacing: 8) {
                            Text("Upgrade to TimeLapse Pro")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundStyle(.primary)
                            
                            Text("Master your time with precision and style")
                                .font(.system(size: 17))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                    .padding(.bottom, 32)
                    
                    // Features list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Premium Features")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            FeatureRow(icon: "calendar.badge.plus", text: "Track up to 5 custom events")
                            FeatureRow(icon: "bell.badge", text: "Personalized notifications for each event")
                            FeatureRow(icon: "square.grid.2x2", text: "Beautiful grid layout visualization")
                            FeatureRow(icon: "app.badge", text: "Interactive home screen widgets")
                            FeatureRow(icon: "paintbrush.fill", text: "Custom color themes for every event")
                            FeatureRow(icon: "square.and.arrow.up", text: "Edit and share your events effortlessly")
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 24)
                    .background(surfaceColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 16)
                    
                    // Subscription options
                    VStack(spacing: 24) {
                        Text("Choose Your Plan")
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.top, 32)
                        
                        PricingOptionsView(paymentManager: paymentManager)
                    }
                    
                    // Terms and privacy
                    VStack(spacing: 6) {
                        Text("By subscribing, you agree to our")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        HStack(spacing: 4) {
                            Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                                .font(.caption.bold())
                                .foregroundStyle(accentColor)
                            
                            Text("and")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Link("Privacy Policy", destination: URL(string: "https://www.wanmenzy.me/privacy-policy")!)
                                .font(.caption.bold())
                                .foregroundStyle(accentColor)
                        }
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal)
            }
            .scrollIndicators(.hidden)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
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
                isLoading = true
                print("SubscriptionView appeared - Loading products")
                
                // Try up to 3 times to load products with a delay between attempts
                for attempt in 1...3 {
                    print("Product loading attempt \(attempt)")
                    await paymentManager.loadProducts()
                    
                    if !paymentManager.products.isEmpty {
                        print("Products loaded successfully on attempt \(attempt)")
                        break
                    }
                    
                    if attempt < 3 {
                        print("Products not loaded, waiting before retry...")
                        try? await Task.sleep(nanoseconds: 1_000_000_000) // Wait 1 second
                    }
                }
                
                print("Final products loaded: \(paymentManager.products.count)")
                if paymentManager.products.isEmpty {
                    print("All product loading attempts failed, using fallback pricing")
                }
                
                isLoading = false
            }
        }
    }
}

struct FeatureRow: View {
    var icon: String
    var text: String
    @Environment(\.colorScheme) private var colorScheme
    
    private var iconColor: Color { Color(hex: "FF7F00") }
    private var textColor: Color { .primary }
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 28, height: 28)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
}

struct PricingOptionsView: View {
    var paymentManager: PaymentManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedOption: ProductType? = nil
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Theme colors
    private var accentColor: Color { Color(hex: "FF7F00") }
    private var backgroundColor: Color { colorScheme == .dark ? Color(UIColor.systemGray6) : Color(UIColor.systemGray6) }
    
    // Product getters
    private var monthlyProduct: Product? {
        paymentManager.products.first(where: { $0.id == ProductType.monthlySubscription.rawValue })
    }
    
    private var yearlyProduct: Product? {
        paymentManager.products.first(where: { $0.id == ProductType.yearlySubscription.rawValue })
    }
    
    private var lifetimeProduct: Product? {
        paymentManager.products.first(where: { $0.id == ProductType.lifetime.rawValue })
    }
    
    // Calculate savings based on actual products
    private var savingsPercentage: String {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else {
            return "Save 24%" // Fallback value
        }
        
        // Extract price values (remove currency symbols)
        if let monthlyPrice = Double(monthly.displayPrice.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)),
           let yearlyPrice = Double(yearly.displayPrice.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)) {
            
            let annualMonthlyPrice = monthlyPrice * 12
            let savings = (annualMonthlyPrice - yearlyPrice) / annualMonthlyPrice
            let savingsPercent = Int(savings * 100)
            
            return "Save \(savingsPercent)%"
        }
        
        return "Save 24%" // Fallback value
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Monthly subscription
            SubscriptionOptionCard(
                title: "Monthly",
                price: monthlyProduct?.displayPrice ?? "USD 0.99",
                subtitle: "7-day free trial",
                isLoading: isLoading && selectedOption == .monthlySubscription,
                action: {
                    selectedOption = .monthlySubscription
                    handlePurchaseWithFeedback(.monthlySubscription)
                }
            )
            
            // Yearly subscription
            SubscriptionOptionCard(
                title: "Yearly",
                price: yearlyProduct?.displayPrice ?? "USD 8.99",
                subtitle: "7-day free trial",
                isLoading: isLoading && selectedOption == .yearlySubscription,
                badge: savingsPercentage,
                action: {
                    selectedOption = .yearlySubscription
                    handlePurchaseWithFeedback(.yearlySubscription)
                }
            )
            
            // Lifetime option
            SubscriptionOptionCard(
                title: "Lifetime",
                price: lifetimeProduct?.displayPrice ?? "USD 19.99",
                subtitle: "One-time purchase",
                isHighlighted: true,
                isLoading: isLoading && selectedOption == .lifetime,
                action: {
                    selectedOption = .lifetime
                    handlePurchaseWithFeedback(.lifetime)
                }
            )
            
            // Restore purchases button
            Button(action: {
                Task {
                    isLoading = true
                    selectedOption = nil
                    do {
                        try await paymentManager.restorePurchases()
                        if paymentManager.isSubscribed || paymentManager.hasLifetimePurchase {
                            dismiss()
                        } else {
                            errorMessage = "No purchases found to restore."
                            showError = true
                        }
                    } catch {
                        errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
                        showError = true
                    }
                    isLoading = false
                }
            }) {
                if isLoading && selectedOption == nil {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(.secondary)
                            .scaleEffect(0.8)
                        Text("Restoring...")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Restore Purchases")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            .disabled(isLoading)
        }
        .padding(.horizontal, 16)
        .alert(isPresented: $showError) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private func handlePurchaseWithFeedback(_ productType: ProductType) {
        // Always provide visual feedback even if we can't find the product
        isLoading = true
        
        print("Handling purchase for: \(productType.rawValue)")
        
        // Simulate slight delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                // Try to get products one more time
                await paymentManager.loadProducts()
                
                if let product = paymentManager.products.first(where: { $0.id == productType.rawValue }) {
                    print("Product found: \(product.id), attempting purchase")
                    do {
                        let success = try await paymentManager.purchase(product)
                        if success {
                            dismiss()
                        } else {
                            errorMessage = "Purchase was not successful. Please try again."
                            showError = true
                        }
                    } catch {
                        print("Purchase error: \(error.localizedDescription)")
                        errorMessage = "Unable to complete purchase: \(error.localizedDescription)"
                        showError = true
                    }
                } else {
                    print("Product not available for purchase: \(productType.rawValue)")
                    errorMessage = "This product is currently unavailable. Please try again later."
                    showError = true
                }
                
                isLoading = false
            }
        }
    }
}

struct SubscriptionOptionCard: View {
    var title: String
    var price: String
    var subtitle: String
    var isHighlighted: Bool = false
    var isLoading: Bool = false
    var badge: String? = nil
    var action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    // Theme colors
    private var accentColor: Color { Color(hex: "FF7F00") }
    private var cardBackground: Color { 
        if isHighlighted {
            return accentColor
        } else {
            return colorScheme == .dark ? Color(UIColor.systemGray5) : Color(UIColor.systemGray6)
        }
    }
    
    private var textColor: Color {
        isHighlighted ? .white : .primary
    }
    
    private var subtitleColor: Color {
        isHighlighted ? .white.opacity(0.9) : .secondary
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(subtitleColor)
                }
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .tint(isHighlighted ? .white : accentColor)
                } else {
                    Text(price)
                        .font(.headline)
                        .foregroundStyle(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isHighlighted ? .white.opacity(0.2) : .clear, lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if let badge = badge {
                    Text(badge)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .clipShape(Capsule())
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .shadow(color: isHighlighted ? accentColor.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(GlobalSettings())
    }
} 
