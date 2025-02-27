import SwiftUI

struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    @EnvironmentObject var globalSettings: GlobalSettings
    
    private let maxVisibleDots = 4
    private let dotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 6
    
    private var visibleRange: ClosedRange<Int> {
        let halfVisible = maxVisibleDots / 2
        let start = max(0, min(currentPage - halfVisible, numberOfPages - maxVisibleDots))
        let end = min(start + maxVisibleDots - 1, numberOfPages - 1)
        return start...end
    }
    
    private func dotScale(for page: Int) -> CGFloat {
        let distance = abs(page - currentPage)
        if distance > 2 { return 0.5 }
        if distance > 1 { return 0.7 }
        return 1.0
    }
    
    private func dotOpacity(for page: Int) -> Double {
        let distance = abs(page - currentPage)
        if distance > 2 { return 0.3 }
        if distance > 1 { return 0.5 }
        return 1.0
    }
    
    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                if visibleRange.contains(page) {
                    Circle()
                        .fill(page == currentPage ? 
                            (globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white) :
                            (globalSettings.effectiveBackgroundStyle == .light ? Color.black.opacity(0.3) : Color.white.opacity(0.3)))
                        .frame(width: dotSize, height: dotSize)
                        .scaleEffect(dotScale(for: page))
                        .opacity(dotOpacity(for: page))
                        .animation(.easeInOut(duration: 0.2), value: currentPage)
                        .onTapGesture {
                            withAnimation {
                                currentPage = page
                            }
                        }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(globalSettings.effectiveBackgroundStyle == .light ? 
                    Color.black.opacity(0.1) : 
                    Color.white.opacity(0.1))
        )
    }
}

struct UIKitPageControl: UIViewRepresentable {
    var numberOfPages: Int
    @Binding var currentPage: Int
    
    func makeUIView(context: Context) -> UIPageControl {
        let control = UIPageControl()
        control.numberOfPages = numberOfPages
        control.currentPage = currentPage
        control.pageIndicatorTintColor = UIColor.lightGray
        control.currentPageIndicatorTintColor = UIColor.white
        control.addTarget(context.coordinator, action: #selector(Coordinator.updateCurrentPage(sender:)), for: .valueChanged)
        return control
    }
    
    func updateUIView(_ uiView: UIPageControl, context: Context) {
        uiView.currentPage = currentPage
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject {
        var control: UIKitPageControl
        
        init(_ control: UIKitPageControl) {
            self.control = control
        }
        
        @objc func updateCurrentPage(sender: UIPageControl) {
            control.currentPage = sender.currentPage
        }
    }
}
