import SwiftUI

// Organic blob shape for smooth theme transitions
struct ThemeTransitionShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Calculate the final radius based on the diagonal of the rect
        let maxRadius = sqrt(pow(rect.width, 2) + pow(rect.height, 2))
        let currentRadius = maxRadius * progress
        
        // Create a more organic blob shape instead of a perfect circle
        let controlPointDistance = currentRadius * 0.55 // Standard value for approximating a circle with bezier curves
        
        // Start point at the top
        let top = CGPoint(x: 0, y: -currentRadius)
        
        // Control points
        let topRight = CGPoint(x: controlPointDistance, y: -currentRadius)
        let rightTop = CGPoint(x: currentRadius, y: -controlPointDistance)
        
        let right = CGPoint(x: currentRadius, y: 0)
        
        let rightBottom = CGPoint(x: currentRadius, y: controlPointDistance)
        let bottomRight = CGPoint(x: controlPointDistance, y: currentRadius)
        
        let bottom = CGPoint(x: 0, y: currentRadius)
        
        let bottomLeft = CGPoint(x: -controlPointDistance, y: currentRadius)
        let leftBottom = CGPoint(x: -currentRadius, y: controlPointDistance)
        
        let left = CGPoint(x: -currentRadius, y: 0)
        
        let leftTop = CGPoint(x: -currentRadius, y: -controlPointDistance)
        let topLeft = CGPoint(x: -controlPointDistance, y: -currentRadius)
        
        // Draw the blob path
        path.move(to: CGPoint(x: 0, y: 0)) // Start at origin
        path.move(to: top)
        path.addCurve(to: right, control1: topRight, control2: rightTop)
        path.addCurve(to: bottom, control1: rightBottom, control2: bottomRight)
        path.addCurve(to: left, control1: bottomLeft, control2: leftBottom)
        path.addCurve(to: top, control1: leftTop, control2: topLeft)
        
        // Add slight random variation to make it more organic
        if progress > 0.1 && progress < 0.9 {
            // Apply subtle distortion when in the middle of the animation
            let distortion = 0.05 * sin(progress * .pi * 4)
            path = path.applying(CGAffineTransform(scaleX: 1.0 + distortion, y: 1.0 - distortion))
        }
        
        return path.offsetBy(dx: 0, dy: 0)
    }
} 