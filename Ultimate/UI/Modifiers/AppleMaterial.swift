import SwiftUI

/// A modern Apple-style material effect for UI components
struct UIMaterial: ViewModifier {
    var style: DesignSystem.MaterialStyle = .regular
    var cornerRadius: CGFloat = DesignSystem.BorderRadius.large
    
    func body(content: Content) -> some View {
        content
            .background(
                style.material,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

// Extension to make the modifier easier to use
extension View {
    func appleMaterial(
        style: DesignSystem.MaterialStyle = .regular,
        cornerRadius: CGFloat = DesignSystem.BorderRadius.large
    ) -> some View {
        self.modifier(UIMaterial(style: style, cornerRadius: cornerRadius))
    }
} 