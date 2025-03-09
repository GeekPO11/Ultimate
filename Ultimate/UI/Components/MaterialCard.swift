import SwiftUI

/// A modern Apple-style card component with glass morphism
struct MaterialCard<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = DesignSystem.BorderRadius.large
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    var materialStyle: DesignSystem.MaterialStyle = .regular
    
    init(
        cornerRadius: CGFloat = DesignSystem.BorderRadius.large,
        padding: EdgeInsets? = nil,
        materialStyle: DesignSystem.MaterialStyle = .regular,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding ?? EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
        self.materialStyle = materialStyle
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                materialStyle.material,
                in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    ZStack {
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 20) {
            MaterialCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Regular Material")
                        .font(DesignSystem.Typography.headline)
                    Text("This is a card with regular material")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            MaterialCard(materialStyle: .ultraThin) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ultra Thin Material")
                        .font(DesignSystem.Typography.headline)
                    Text("This is a card with ultra thin material")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            MaterialCard(materialStyle: .thick) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Thick Material")
                        .font(DesignSystem.Typography.headline)
                    Text("This is a card with thick material")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
} 