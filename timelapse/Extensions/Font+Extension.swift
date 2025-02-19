import SwiftUI

extension Font {
    static func inter(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        return .custom("Inter", size: size).weight(weight)
    }
}
