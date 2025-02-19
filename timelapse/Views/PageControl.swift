import SwiftUI

struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    @EnvironmentObject var globalSettings: GlobalSettings
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? 
                        (globalSettings.effectiveBackgroundStyle == .light ? Color.black : Color.white) :
                        (globalSettings.effectiveBackgroundStyle == .light ? Color.black.opacity(0.3) : Color.white.opacity(0.3)))
                    .frame(width: 8, height: 8)
            }
        }
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
