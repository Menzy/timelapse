import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct NoiseBackground: View {
    let darkColor: Color
    let lightColor: Color
    @EnvironmentObject var globalSettings: GlobalSettings // Use global settings
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: globalSettings.backgroundStyle == .light ? [Color.white, Color.gray] : [darkColor, lightColor]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // First noise layer
            Image(uiImage: generateNoiseImage(scale: 0.8))
                .resizable()
                .blendMode(.overlay)
                .opacity(0.4)
            
            // Second noise layer with different scale
            Image(uiImage: generateNoiseImage(scale: 0.7))
                .resizable()
                .blendMode(.softLight)
                .opacity(0.3)
        }
        .ignoresSafeArea()
    }
    
    private func generateNoiseImage(scale: CGFloat) -> UIImage {
        let context = CIContext()
        let noiseFilter = CIFilter.randomGenerator()
        
        guard let outputImage = noiseFilter.outputImage else {
            return UIImage()
        }
        
        let resizedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        
        // Apply contrast to make the noise more visible
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.setValue(resizedImage, forKey: kCIInputImageKey)
        contrastFilter.setValue(1.1, forKey: kCIInputContrastKey)
        
        guard let contrastedImage = contrastFilter.outputImage,
              let cgImage = context.createCGImage(contrastedImage, from: contrastedImage.extent) else {
            return UIImage()
        }
        
        return UIImage(cgImage: cgImage)
    }
}
