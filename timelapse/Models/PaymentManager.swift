import StoreKit
import SwiftUI

// Product identifiers
enum ProductType: String, CaseIterable {
    case lifetime = "lifetime1"
    case yearlySubscription = "timelapseAnnualSubscription1"
    case monthlySubscription = "timelapseMonthlySubscription1"
}

class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var isSubscribed = false
    @Published var hasLifetimePurchase = false
    @Published var isInTrialPeriod = false
    @Published var trialEndDate: Date?
    
    private var productIDs = ProductType.allCases.map { $0.rawValue }
    private var updateListenerTask: Task<Void, Error>?
    
    // Make this internal so it can be accessed when needed
    func generateMockProducts() {
        print("Using fallback pricing display since products can't be loaded")
        // Keep using the fallback pricing view which doesn't require actual products
        products = []
    }
    
    init() {
        // Start listening for transactions
        updateListenerTask = listenForTransactions()
        
        // Load cached subscription status from UserDefaults
        isSubscribed = UserDefaults.standard.bool(forKey: "isSubscribed")
        hasLifetimePurchase = UserDefaults.standard.bool(forKey: "hasLifetimePurchase")
        isInTrialPeriod = UserDefaults.standard.bool(forKey: "isInTrialPeriod")
        if let endDateTimestamp = UserDefaults.standard.object(forKey: "trialEndDate") as? Date {
            trialEndDate = endDateTimestamp
        }
        
        // Check if this is first launch and handle initial free trial period
        checkFirstLaunchAndSetupTrialIfNeeded()
        
        // Load products in background without blocking
        Task {
            await loadProducts()
            
            // Only check with StoreKit if we don't have a cached status
            // or periodically to keep things fresh (about 1 in 10 launches)
            if !isSubscribed && !hasLifetimePurchase {
                await updateSubscriptionStatus()
            }
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    @MainActor
    func loadProducts() async {
        print("Attempting to load products with IDs: \(productIDs)")
        
        // If in a simulator or testing environment, handle accordingly
        #if DEBUG
        print("Running in DEBUG mode")
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            print("Running in Xcode previews - using mock products")
            generateMockProducts()
            return
        }
        #endif
        
        do {
            let storeProducts = try await Product.products(for: productIDs)
            print("Successfully loaded \(storeProducts.count) products from Store")
            
            // Log all loaded products
            for product in storeProducts {
                print("Loaded product: \(product.id) - \(product.displayName) - \(product.displayPrice)")
            }
            
            self.products = storeProducts
            
            // If no products were loaded, try using another approach
            if storeProducts.isEmpty {
                print("No products loaded from Store, trying alternate loading method")
                retryProductLoading()
            }
        } catch {
            print("Failed to load products: \(error.localizedDescription)")
            // Try using fallback approach
            retryProductLoading()
        }
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        print("Updating subscription status")
        var purchasedProducts: [Product] = []
        var lifetimePurchased = false
        var inTrialPeriod = false
        var trialExpirationDate: Date? = nil
        
        // Store current status to check for changes
        let wasSubscribed = isSubscribed
        
        // Transaction.currentEntitlements doesn't throw so we don't need a try/catch
        for await result in Transaction.currentEntitlements {
            switch result {
            case .verified(let transaction):
                print("Found verified entitlement: \(transaction.productID)")
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchasedProducts.append(product)
                    
                    // Check if this is a lifetime purchase
                    if product.id == ProductType.lifetime.rawValue {
                        lifetimePurchased = true
                        print("Lifetime purchase verified")
                    }
                    
                    // Check if this is a subscription in trial period
                    if product.id == ProductType.monthlySubscription.rawValue || product.id == ProductType.yearlySubscription.rawValue {
                        // Use the StoreKit expirationDate as the trial/subscription end date
                        // rather than manually calculating
                        if let expirationDate = transaction.expirationDate {
                            print("Found subscription with expiration date: \(expirationDate)")
                            
                            // Check if this is a trial
                            // A trial can be detected by checking if the current date is close to
                            // the original purchase date (within a week) and there's an expiration date
                            let purchaseDate = transaction.purchaseDate
                            let now = Date()
                            let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: now).day ?? 0
                            
                            // If it's been less than 8 days since purchase, likely in trial period
                            if daysSincePurchase < 8 {
                                inTrialPeriod = true
                                trialExpirationDate = expirationDate
                                print("User is in trial period until \(expirationDate)")
                            }
                        }
                    }
                }
            case .unverified(let transaction, let error):
                print("Unverified transaction found: \(transaction.productID), error: \(error.localizedDescription)")
                // For sandbox testing, we might want to still count this transaction
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    print("Including unverified product in purchases: \(product.id)")
                    purchasedProducts.append(product)
                    
                    if product.id == ProductType.lifetime.rawValue {
                        lifetimePurchased = true
                    }
                    
                    // Check if this is a subscription in trial period (even if unverified)
                    if product.id == ProductType.monthlySubscription.rawValue || product.id == ProductType.yearlySubscription.rawValue {
                        // Use the StoreKit expirationDate rather than manually calculating
                        if let expirationDate = transaction.expirationDate {
                            print("Found subscription with expiration date: \(expirationDate)")
                            
                            // Check if this is a trial
                            let purchaseDate = transaction.purchaseDate
                            let now = Date()
                            let daysSincePurchase = Calendar.current.dateComponents([.day], from: purchaseDate, to: now).day ?? 0
                            
                            // If it's been less than 8 days since purchase, likely in trial period
                            if daysSincePurchase < 8 {
                                inTrialPeriod = true
                                trialExpirationDate = expirationDate
                                print("User is in trial period until \(expirationDate)")
                            }
                        }
                    }
                }
            }
        }
        
        self.purchasedSubscriptions = purchasedProducts
        self.hasLifetimePurchase = lifetimePurchased
        self.isSubscribed = !purchasedProducts.isEmpty
        self.isInTrialPeriod = inTrialPeriod
        self.trialEndDate = trialExpirationDate
        
        print("Subscription status updated - isSubscribed: \(isSubscribed), hasLifetimePurchase: \(hasLifetimePurchase), isInTrialPeriod: \(isInTrialPeriod)")
        
        // Save subscription status to UserDefaults for access across the app
        UserDefaults.standard.set(isSubscribed, forKey: "isSubscribed")
        UserDefaults.standard.set(hasLifetimePurchase, forKey: "hasLifetimePurchase")
        UserDefaults.standard.set(isInTrialPeriod, forKey: "isInTrialPeriod")
        UserDefaults.standard.set(trialExpirationDate, forKey: "trialEndDate")
        
        // Also save to shared UserDefaults for widget access
        UserDefaults.shared?.set(isSubscribed, forKey: "isSubscribed")
        UserDefaults.shared?.set(hasLifetimePurchase, forKey: "hasLifetimePurchase")
        UserDefaults.shared?.set(isInTrialPeriod, forKey: "isInTrialPeriod")
        UserDefaults.shared?.set(trialExpirationDate, forKey: "trialEndDate")
        
        // If subscription status changed, post a notification so the UI can refresh
        if wasSubscribed != isSubscribed {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("SubscriptionStatusChanged"), object: nil)
            }
        }
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        do {
            // Start the purchase with better user feedback
            print("Initiating purchase for product: \(product.id)")
            
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                // Handle the verification result
                switch verification {
                case .verified(let transaction):
                    print("Transaction verified successfully: \(transaction.productID)")
                    // Handle successful purchase
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    return true
                case .unverified(_, let error):
                    // Log the verification error
                    print("Transaction verification failed: \(error.localizedDescription)")
                    return false
                @unknown default:
                    print("Unknown verification result")
                    return false
                }
            case .userCancelled:
                print("Purchase was cancelled by user")
                return false
            case .pending:
                print("Purchase is pending approval")
                return false
            @unknown default:
                print("Unknown purchase result")
                return false
            }
        } catch {
            // Log the specific error for debugging
            print("StoreKit purchase error: \(error.localizedDescription)")
            if let skError = error as? StoreKit.Product.PurchaseError {
                print("StoreKit purchase error code: \(skError)")
            }
            throw error
        }
    }
    
    func restorePurchases() async throws {
        print("Starting restore purchases process")
        do {
            // Sync with App Store to fetch latest transaction status
            try await AppStore.sync()
            print("AppStore sync completed successfully")
            await updateSubscriptionStatus()
        } catch {
            print("Restore purchases failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            // Listen for transactions from App Store
            // Transaction.updates doesn't throw so we don't need a try/catch around the for-await
            for await result in Transaction.updates {
                switch result {
                case .verified(let transaction):
                    // Handle the transaction and deliver content to the user
                    print("Verified transaction update: \(transaction.productID)")
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                case .unverified(let transaction, let error):
                    // Handle unverified transaction
                    print("Unverified transaction: \(error.localizedDescription)")
                    // Still finish the transaction even if unverified
                    await transaction.finish()
                }
            }
        }
    }
    
    // Helper method to check if user is subscribed
    static func isUserSubscribed() -> Bool {
        return UserDefaults.standard.bool(forKey: "isSubscribed")
    }
    
    // Helper method to check if user has lifetime purchase
    static func hasLifetimePurchase() -> Bool {
        return UserDefaults.standard.bool(forKey: "hasLifetimePurchase")
    }
    
    // Helper method to check if user is in trial period
    static func isInTrialPeriod() -> Bool {
        // First check if trial period flag is set
        if !UserDefaults.standard.bool(forKey: "isInTrialPeriod") {
            return false
        }
        
        // Then check if the trial end date is still in the future
        if let endDate = UserDefaults.standard.object(forKey: "trialEndDate") as? Date {
            return endDate > Date()
        }
        
        return false
    }
    
    // Helper method to get trial period end date
    static func getTrialEndDate() -> Date? {
        // Return the trial end date from UserDefaults if it exists
        return UserDefaults.standard.object(forKey: "trialEndDate") as? Date
    }
    
    // Helper method to get days left in trial period
    static func getDaysLeftInTrial() -> Int? {
        guard isInTrialPeriod(), let endDate = getTrialEndDate() else {
            return nil
        }
        
        let calendar = Calendar.current
        // We want to count the current day if it's not over yet
        let now = Date()
        
        // Calculate components including partial days
        let components = calendar.dateComponents([.day, .hour, .minute], from: now, to: endDate)
        
        // If there are hours/minutes left but day component is 0, show as "1 day" remaining
        if let days = components.day, let hours = components.hour, let minutes = components.minute {
            if days == 0 && (hours > 0 || minutes > 0) {
                return 1
            }
            return max(0, days)
        }
        
        // Fallback to just days
        return components.day
    }
    
    // Helper method to get the event limit based on subscription status
    static func getEventLimit() -> Int {
        // Free users can only create 1 custom event (plus the year tracker)
        // Premium users can create up to 5 custom events
        return isUserSubscribed() || hasLifetimePurchase() ? 5 : 1
    }
    
    private func retryProductLoading() {
        print("Attempting to retry product loading using a different approach")
        Task {
            // Wait a brief moment and try loading products again
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
            
            do {
                // Try a different approach for production - simple retry with delay
                print("Retrying product load after delay")
                let retryProducts = try await Product.products(for: productIDs)
                
                await MainActor.run {
                    if !retryProducts.isEmpty {
                        self.products = retryProducts
                        print("Successfully loaded \(retryProducts.count) products on retry")
                    } else {
                        print("Still no products found on retry")
                        generateMockProducts()
                    }
                }
            } catch {
                print("Failed to load products on retry: \(error.localizedDescription)")
                await MainActor.run { generateMockProducts() }
            }
        }
    }
    
    // Helper to check if this is first launch and setup trial if needed
    private func checkFirstLaunchAndSetupTrialIfNeeded() {
        // Skip this if the user is already in a transaction-based subscription
        if isSubscribed || hasLifetimePurchase {
            print("User already has a subscription or lifetime purchase, skipping first launch trial setup")
            return
        }
        
        // Check if first launch date is recorded
        if UserDefaults.standard.object(forKey: "firstLaunchDate") == nil {
            // This is first launch, record the date
            let firstLaunchDate = Date()
            UserDefaults.standard.set(firstLaunchDate, forKey: "firstLaunchDate")
            
            // We won't set an automatic trial here anymore
            // We'll let the StoreKit transactions determine trial status
            print("First launch detected, recorded date: \(firstLaunchDate)")
        }
    }
    
    // Validate trial period based on first launch date
    private func validateTrialPeriodBasedOnFirstLaunch() {
        // If user is already in a transaction-based trial or subscription,
        // we don't want to override that with the first-launch trial
        if isSubscribed || isInTrialPeriod || trialEndDate != nil {
            return
        }
        
        // We're leaving this method mostly for backward compatibility,
        // but we won't be setting trial periods based on first launch anymore.
        // Trial periods should come from StoreKit transactions only.
    }
}
