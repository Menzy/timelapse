import StoreKit
import SwiftUI

// Product identifiers
enum SubscriptionType: String, CaseIterable {
    case monthly = "com.wanmenzy.timelapse.subscription.monthly"
    case yearly = "com.wanmenzy.timelapse.subscription.yearly"
}

class PaymentManager: ObservableObject {
    static let shared = PaymentManager()
    
    @Published var products: [Product] = []
    @Published var purchasedSubscriptions: [Product] = []
    @Published var isSubscribed = false
    
    private var productIDs = SubscriptionType.allCases.map { $0.rawValue }
    private var updateListenerTask: Task<Void, Error>?
    
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
        do {
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func updateSubscriptionStatus() async {
        var purchasedProducts: [Product] = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if let product = products.first(where: { $0.id == transaction.productID }) {
                    purchasedProducts.append(product)
                }
            }
        }
        
        self.purchasedSubscriptions = purchasedProducts
        self.isSubscribed = !purchasedProducts.isEmpty
        
        // Save subscription status to UserDefaults for access across the app
        UserDefaults.standard.set(isSubscribed, forKey: "isSubscribed")
        
        // Also save to shared UserDefaults for widget access
        UserDefaults.shared?.set(isSubscribed, forKey: "isSubscribed")
    }
    
    func purchase(_ product: Product) async throws -> Bool {
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    // Handle successful purchase
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    return true
                } else {
                    // Handle unverified transaction
                    return false
                }
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("Purchase failed: \(error)")
            throw error
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    // Handle transaction
                    await transaction.finish()
                    await self.updateSubscriptionStatus()
                }
            }
        }
    }
    
    // Helper method to check if user is subscribed
    static func isUserSubscribed() -> Bool {
        return UserDefaults.standard.bool(forKey: "isSubscribed")
    }
    
    // Helper method to get the event limit based on subscription status
    static func getEventLimit() -> Int {
        return isUserSubscribed() ? Int.max : 1 // Free users can only create 1 custom event
    }
}
