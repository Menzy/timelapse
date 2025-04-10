import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        
        // Handle iPad presentation properly
        if UIDevice.current.userInterfaceIdiom == .pad {
            // In iOS 15+, get the active scene's window
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController,
               let sourceView = rootVC.view {
                controller.popoverPresentationController?.sourceView = sourceView
                controller.popoverPresentationController?.sourceRect = CGRect(
                    x: sourceView.bounds.midX,
                    y: sourceView.bounds.midY,
                    width: 0, height: 0
                )
                controller.popoverPresentationController?.permittedArrowDirections = []
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareableCardView: View {
    let title: String
    let event: Event
    let settings: DisplaySettings
    let eventStore: EventStore
    let daysLeft: Int
    let totalDays: Int
    let showingDaysLeft: Bool
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage? = nil
    @State private var isSharePresented: Bool = false
    @State private var isGeneratingImage: Bool = false
    
    // Check if this is the year tracker
    private var isYearTracker: Bool {
        return title == String(Calendar.current.component(.year, from: Date()))
    }
    
    // Get proper card dimensions for the device
    private var cardWidth: CGFloat {
        DeviceType.timeCardWidth(isLandscape: false)
    }
    
    private var cardHeight: CGFloat {
        DeviceType.timeCardHeight(isLandscape: false)
    }
    
    // Preview container size
    private var previewWidth: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        return DeviceType.isIPad ? screenWidth * 0.6 : screenWidth * 0.9
    }
    
    private var previewHeight: CGFloat {
        let screenHeight = UIScreen.main.bounds.height
        return DeviceType.isIPad ? screenHeight * 0.5 : screenHeight * 0.6
    }
    
    var body: some View {
        VStack {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(globalSettings.invertedColor)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text(isYearTracker ? "Share Your Year" : "Share Event")
                    .scaledFont(name: "Inter", size: 18)
                    .foregroundColor(globalSettings.invertedColor)
                
                Spacer()
                
                Button(action: {
                    shareEvent()
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(globalSettings.invertedColor)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            Spacer()
            
            // Preview of the card to be shared
            ZStack {
                // Background for the card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: previewWidth, height: previewHeight)
                
                // The actual card
                ShareableTimeCard(
                    title: title,
                    event: event,
                    settings: settings,
                    eventStore: eventStore,
                    daysLeft: daysLeft,
                    totalDays: totalDays,
                    showingDaysLeft: showingDaysLeft
                )
                .environmentObject(globalSettings)
            }
            
            Spacer()
        }
        .background(globalSettings.effectiveBackgroundStyle.backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $isSharePresented) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
        .overlay {
            if isGeneratingImage {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .overlay {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                    }
            }
        }
    }
    
    private func shareEvent() {
        isGeneratingImage = true
        
        // Use device-appropriate sizing for the image generation
        let imageWidth = DeviceType.isIPad ? cardWidth * 1.2 : UIScreen.main.bounds.width * 0.9
        let imageHeight = DeviceType.isIPad ? cardHeight * 1.3 : UIScreen.main.bounds.height * 0.6
        
        // Create a container view with proper padding and background
        let containerView = ZStack {
            // Apply background color to the entire view
            globalSettings.effectiveBackgroundStyle.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Add some top padding
                Spacer()
                    .frame(height: 40)
                
                // The card with its background
                ShareableTimeCard(
                    title: title,
                    event: event,
                    settings: settings,
                    eventStore: eventStore,
                    daysLeft: daysLeft,
                    totalDays: totalDays,
                    showingDaysLeft: showingDaysLeft
                )
                .environmentObject(globalSettings)
                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // Add some bottom padding
                Spacer()
                    .frame(height: 40)
                
                // Watermark
                Text(isYearTracker ? "My Year so Far - Created with Timelapse" : "Created with Timelapse")
                    .scaledFont(name: "Inter", size: 8)
                    .foregroundColor(globalSettings.effectiveBackgroundStyle == .light ? .black.opacity(0.7) : .white.opacity(0.7))
                    .padding(.top, 16)
            }
            .frame(width: imageWidth)
            .padding(.horizontal, 20)
        }
        .cornerRadius(20)
        
        // Generate image with device-appropriate dimensions
        let size = CGSize(
            width: imageWidth,
            height: imageHeight
        )
        
        // Generate the image asynchronously
        DispatchQueue.main.async {
            // Create a UIHostingController with the container view
            let controller = UIHostingController(rootView: containerView)
            controller.view.frame = CGRect(origin: .zero, size: size)
            controller.view.bounds = CGRect(origin: .zero, size: size)
            
            // Ensure the background color is applied correctly
            controller.view.backgroundColor = UIColor(globalSettings.effectiveBackgroundStyle.backgroundColor)
            
            // Render the image
            let renderer = UIGraphicsImageRenderer(size: size)
            shareImage = renderer.image { _ in
                controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
            }
            
            isGeneratingImage = false
            isSharePresented = true
        }
    }
} 
