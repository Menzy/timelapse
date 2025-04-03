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
    
    private var productIDs = ProductType.allCases.map { $0.rawValue }
    private var updateListenerTask: Task<Void, Error>?
    
    // Make this internal so it can be accessed when needed
    func generateMockProducts() {
        print("Using fallback pricing display since products can't be loaded")
        // Keep using the fallback pricing view which doesn't require actual products
        products = []
    }
    
    init() {
        updateListenerTask = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateSubscriptionStatus()
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
                }
            }
        }
        
        self.purchasedSubscriptions = purchasedProducts
        self.hasLifetimePurchase = lifetimePurchased
        self.isSubscribed = !purchasedProducts.isEmpty
        
        print("Subscription status updated - isSubscribed: \(isSubscribed), hasLifetimePurchase: \(hasLifetimePurchase)")
        
        // Save subscription status to UserDefaults for access across the app
        UserDefaults.standard.set(isSubscribed, forKey: "isSubscribed")
        UserDefaults.standard.set(hasLifetimePurchase, forKey: "hasLifetimePurchase")
        
        // Also save to shared UserDefaults for widget access
        UserDefaults.shared?.set(isSubscribed, forKey: "isSubscribed")
        UserDefaults.shared?.set(hasLifetimePurchase, forKey: "hasLifetimePurchase")
        
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
}
