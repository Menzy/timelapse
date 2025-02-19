import SwiftUI

struct AnimatedText: View {
    let text: String
    @State private var opacity: [Double]
    @State private var previousText: String
        @State private var offsets: [CGFloat]
    
    init(text: String) {
        self.text = text
        self._previousText = State(initialValue: text)
        self._opacity = State(initialValue: Array(repeating: 1.0, count: text.count))
        self._offsets = State(initialValue: Array(repeating: 0, count: text.count))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { index, character in
                Text(String(character))
                    .opacity(index < opacity.count ? opacity[index] : 0)
                    .offset(y: index < offsets.count ? offsets[index] : 0)
            }
        }
        .onChange(of: text) { oldValue, newValue in
            // Reset opacity array with new size before animation
            opacity = Array(repeating: 0.0, count: newValue.count)
            offsets = Array(repeating: 20, count: newValue.count) // Start 20 points below
            
            // Ensure previous text is updated
            previousText = text
            
            // Animate new text
            for index in 0..<newValue.count {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05)) {
                    opacity[index] = 1.0
                    offsets[index] = 0 // Animate to original position
                }
            }
        }
    }
}
