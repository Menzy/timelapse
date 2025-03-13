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
    @EnvironmentObject var globalSettings: GlobalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var shareImage: UIImage? = nil
    @State private var isSharePresented: Bool = false
    
    // Check if this is the year tracker
    private var isYearTracker: Bool {
        return title == String(Calendar.current.component(.year, from: Date()))
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
                
                Text(isYearTracker ? "Share Year Tracker" : "Share Event")
                    .font(.custom("Inter", size: 18))
                    .foregroundColor(globalSettings.invertedColor)
                
                Spacer()
                
                Button(action: {
                    // Generate the image and present share sheet
                    generateShareImage()
                    isSharePresented = true
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
                    .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.6)
                
                // The actual card
                ShareableTimeCard(
                    title: title,
                    event: event,
                    settings: settings,
                    eventStore: eventStore,
                    daysLeft: daysLeft,
                    totalDays: totalDays
                )
                .environmentObject(globalSettings)
            }
            
            Spacer()
            
            // Share button
            Button(action: {
                // Generate the image and present share sheet
                generateShareImage()
                isSharePresented = true
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share")
                }
                .font(.custom("Inter", size: 16))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
        .background(globalSettings.effectiveBackgroundStyle.backgroundColor.edgesIgnoringSafeArea(.all))
        .sheet(isPresented: $isSharePresented) {
            if let image = shareImage {
                ShareSheet(activityItems: [image])
            }
        }
    }
    
    private func generateShareImage() {
        // Create the shareable card view with padding for the watermark
        let cardView = VStack(spacing: 8) {
            ShareableTimeCard(
                title: title,
                event: event,
                settings: settings,
                eventStore: eventStore,
                daysLeft: daysLeft,
                totalDays: totalDays
            )
            .environmentObject(globalSettings)
        }
        .padding(16)
        .background(globalSettings.effectiveBackgroundStyle.backgroundColor)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        
        // Convert the view to an image with extra space for the watermark
        let size = CGSize(width: UIScreen.main.bounds.width * 0.85, height: UIScreen.main.bounds.height * 0.55)
        shareImage = cardView.asImage(size: size)
    }
} 
