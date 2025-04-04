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
                        FeatureRow(icon: "calendar.badge.plus", text: "Create and customize up to 5 custom events (free tier: 1)")
                        FeatureRow(icon: "bell.badge", text: "Personalize notifications for each event")
                        FeatureRow(icon: "square.grid.2x2", text: "View all events in a beautiful, organized grid layout")
                        FeatureRow(icon: "app.badge", text: "Access custom events as interactive widgets")
                        FeatureRow(icon: "paintbrush.fill", text: "Customize event appearance with custom hex colors")
                        FeatureRow(icon: "square.and.arrow.up", text: "Edit, style, and share your events effortlessly")
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 20)
                    
                    // Subscription options - ALWAYS use the new blue button design
                    PricingOptionsView(paymentManager: paymentManager)
                    
                    // Terms and privacy
                    VStack(spacing: 5) {
                        Text("By subscribing, you agree to our")
                            .font(.system(size: 12))
                        
                        HStack(spacing: 5) {
                            Link("Terms of Service", destination: URL(string: "https://www.wanmenzy.me/terms")!)
                                .foregroundColor(Color(hex: "FF7F00"))
                            Text("and")
                            Link("Privacy Policy", destination: URL(string: "https://www.wanmenzy.me/privacy-policy")!)
                                .foregroundColor(Color(hex: "FF7F00"))
                        }
                        .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color.secondary)
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
                        .foregroundColor(Color.primary)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        if let savingsText = savingsText {
                            Text(savingsText)
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                        } else {
                            Text(product.description)
                                .font(.system(size: 14))
                                .foregroundColor(Color.secondary)
                        }
                        
                        Text(formattedTrialPeriod)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "FF7F00"))
                    }
                }
                
                Spacer()
                
                Text(product.displayPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.primary)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
            Button(action: {
                Task {
                    isLoading = true
                    do {
                        print("Starting subscription purchase for: \(product.id)")
                        let success = try await paymentManager.purchase(product)
                        print("Subscription purchase result: \(success)")
                        if success {
                            dismiss()
                        } else {
                            errorMessage = "Purchase process completed but was not successful. Please try again."
                            showError = true
                        }
                    } catch {
                        print("Subscription purchase error: \(error.localizedDescription)")
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
        .background(Color(UIColor.systemGray6))
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
                        .foregroundColor(Color.primary)
                    
                    Text("One-time purchase")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondary)
                    
                    Text("Pay once, use forever")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(hex: "FF7F00"))
                        .padding(.top, 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.primary)
                    
                    Text("one time")
                        .font(.system(size: 12))
                        .foregroundColor(Color.secondary)
                }
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 10)
            
            Button(action: {
                Task {
                    isLoading = true
                    do {
                        print("Starting lifetime purchase for: \(product.id)")
                        let success = try await paymentManager.purchase(product)
                        print("Lifetime purchase result: \(success)")
                        if success {
                            dismiss()
                        } else {
                            errorMessage = "Purchase process completed but was not successful. Please try again."
                            showError = true
                        }
                    } catch {
                        print("Lifetime purchase error: \(error.localizedDescription)")
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
        .background(Color(UIColor.systemGray6))
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
        VStack(spacing: 25) {
            // Subscription header
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
            
            // Monthly and Yearly options side by side
            HStack(spacing: 15) {
                // Monthly option
                Button(action: { 
                    selectedOption = .monthlySubscription
                    handlePurchaseWithFeedback(.monthlySubscription)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(hex: "FF7F00").opacity(isLoading && selectedOption == .monthlySubscription ? 0.6 : 0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        
                        VStack(spacing: 3) {
                            if let product = monthlyProduct {
                                // Dynamic price from App Store Connect
                                Text(product.displayPrice)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("monthly")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            } else {
                                // Fallback hardcoded price
                                Text("USD 0.99")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("monthly")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 10)
                        .opacity(isLoading && selectedOption == .monthlySubscription ? 0.7 : 1)
                        
                        if isLoading && selectedOption == .monthlySubscription {
                            HStack(spacing: 4) {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 5, height: 5)
                                        .opacity(0.7)
                                        .scaleEffect(isLoading ? 1 : 0.5)
                                        .animation(
                                            Animation.easeInOut(duration: 0.4)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(i) * 0.2),
                                            value: isLoading
                                        )
                                }
                            }
                        }
                    }
                    .frame(height: 65)
                }
                .disabled(isLoading)
                
                // Yearly option
                Button(action: { 
                    selectedOption = .yearlySubscription
                    handlePurchaseWithFeedback(.yearlySubscription)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 30)
                            .fill(Color(hex: "FF7F00").opacity(isLoading && selectedOption == .yearlySubscription ? 0.6 : 0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 30)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                        
                        VStack(spacing: 3) {
                            if let product = yearlyProduct {
                                // Dynamic price from App Store Connect
                                Text(product.displayPrice)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("yearly")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            } else {
                                // Fallback hardcoded price
                                Text("USD 8.99")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(.white)
                                Text("yearly")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.vertical, 10)
                        .opacity(isLoading && selectedOption == .yearlySubscription ? 0.7 : 1)
                        
                        if isLoading && selectedOption == .yearlySubscription {
                            HStack(spacing: 4) {
                                ForEach(0..<3) { i in
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 5, height: 5)
                                        .opacity(0.7)
                                        .scaleEffect(isLoading ? 1 : 0.5)
                                        .animation(
                                            Animation.easeInOut(duration: 0.4)
                                                .repeatForever(autoreverses: true)
                                                .delay(Double(i) * 0.2),
                                            value: isLoading
                                        )
                                }
                            }
                        }
                        
                        // Save badge with dynamic percentage
                        VStack {
                            HStack {
                                Spacer()
                                Text(savingsPercentage)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(
                                        Capsule()
                                            .fill(Color.green.opacity(0.9))
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                                            )
                                    )
                                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                                    .padding(.top, -6)
                                    .padding(.trailing, 6)
                            }
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(height: 65)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal)
            
            // Lifetime option below
            Button(action: { 
                selectedOption = .lifetime
                handlePurchaseWithFeedback(.lifetime)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(hex: "FF7F00").opacity(isLoading && selectedOption == .lifetime ? 0.6 : 0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    
                    VStack(spacing: 3) {
                        if let product = lifetimeProduct {
                            // Dynamic price from App Store Connect
                            Text(product.displayPrice)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            Text("lifetime access")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        } else {
                            // Fallback hardcoded price
                            Text("USD 19.99")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white)
                            Text("lifetime access")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                    .padding(.vertical, 10)
                    .opacity(isLoading && selectedOption == .lifetime ? 0.7 : 1)
                    
                    if isLoading && selectedOption == .lifetime {
                        HStack(spacing: 4) {
                            ForEach(0..<3) { i in
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 5, height: 5)
                                    .opacity(0.7)
                                    .scaleEffect(isLoading ? 1 : 0.5)
                                    .animation(
                                        Animation.easeInOut(duration: 0.4)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(i) * 0.2),
                                        value: isLoading
                                    )
                            }
                        }
                    }
                }
                .frame(height: 65)
                .padding(.horizontal)
            }
            .disabled(isLoading)
            
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
                Text(isLoading && selectedOption == nil ? "Restoring..." : "Restore Purchases")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isLoading && selectedOption == nil ? Color.secondary.opacity(0.7) : Color.secondary)
                    .opacity(isLoading && selectedOption == nil ? 0.7 : 1)
            }
            .padding(.top, 20)
            .disabled(isLoading)
        }
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
    
    // Keep old method for backward compatibility
    private func handlePurchase(_ productType: ProductType) {
        handlePurchaseWithFeedback(productType)
    }
}

struct SubscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SubscriptionView()
            .environmentObject(GlobalSettings())
    }
} 
