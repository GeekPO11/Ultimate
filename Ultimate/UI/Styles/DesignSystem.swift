import SwiftUI

/// Modern design system for the Ultimate app with glass morphism
enum DesignSystem {
    /// Color palette for the app
    enum Colors {
        // Light Mode
        static let backgroundLight = Color(hex: "F8F9FA")
        static let cardBackgroundLight = Color.white.opacity(0.7)
        static let primaryTextLight = Color(hex: "212529")
        static let secondaryTextLight = Color(hex: "6C757D")
        static let primaryActionLight = Color(hex: "2ECB71") // Green
        static let secondaryActionLight = Color(hex: "339AF0") // Blue
        static let accentLight = Color(hex: "FF6B6B") // Coral
        static let dividersLight = Color(hex: "DEE2E6")
        
        // Dark Mode
        static let backgroundDark = Color(hex: "212529")
        static let cardBackgroundDark = Color(hex: "343A40").opacity(0.7)
        static let primaryTextDark = Color(hex: "F8F9FA")
        static let secondaryTextDark = Color(hex: "ADB5BD")
        static let primaryActionDark = Color(hex: "2ECB71").opacity(0.9) // Slightly adjusted
        static let secondaryActionDark = Color(hex: "339AF0").opacity(0.9) // Slightly adjusted
        static let accentDark = Color(hex: "FF6B6B").opacity(0.9) // Slightly adjusted
        static let dividersDark = Color(hex: "495057")
        
        // Neon Colors
        static let neonBlue = Color.blue.opacity(0.8)
        static let neonCyan = Color.cyan.opacity(0.8)
        static let neonGreen = Color.green.opacity(0.8)
        static let neonPurple = Color.purple.opacity(0.8)
        static let neonPink = Color.pink.opacity(0.8)
        static let neonOrange = Color.orange.opacity(0.8)
        
        // Dynamic colors that adapt to light/dark mode
        static var background: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(backgroundDark) : UIColor(backgroundLight) })
        }
        
        static var cardBackground: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(cardBackgroundDark) : UIColor(cardBackgroundLight) })
        }
        
        static var primaryText: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(primaryTextDark) : UIColor(primaryTextLight) })
        }
        
        static var secondaryText: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(secondaryTextDark) : UIColor(secondaryTextLight) })
        }
        
        static var primaryAction: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(primaryActionDark) : UIColor(primaryActionLight) })
        }
        
        static var secondaryAction: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(secondaryActionDark) : UIColor(secondaryActionLight) })
        }
        
        static var accent: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(accentDark) : UIColor(accentLight) })
        }
        
        static var dividers: Color {
            Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dividersDark) : UIColor(dividersLight) })
        }
    }
    
    /// Typography for the app
    enum Typography {
        // Font sizes following Dynamic Type
        static let largeTitle: Font = .largeTitle
        static let title1: Font = .title
        static let title2: Font = .title2
        static let title3: Font = .title3
        static let headline: Font = .headline
        static let body: Font = .body
        static let callout: Font = .callout
        static let subheadline: Font = .subheadline
        static let footnote: Font = .footnote
        static let caption1: Font = .caption
        static let caption2: Font = .caption2
    }
    
    /// Spacing system for the app
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let s: CGFloat = 12
        static let m: CGFloat = 16
        static let l: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    /// Border radius values
    enum BorderRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 24
        static let pill: CGFloat = 9999
    }
    
    /// Shadow levels
    enum Elevation {
        static let level1: Shadow = Shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let level2: Shadow = Shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let level3: Shadow = Shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 8)
        static let level4: Shadow = Shadow(color: .black.opacity(0.25), radius: 24, x: 0, y: 12)
    }
    
    /// Material style options
    enum MaterialStyle {
        case regular
        case thin
        case ultraThin
        case thick
        case ultraThick
        
        var material: AnyShapeStyle {
            switch self {
            case .regular:
                return AnyShapeStyle(.regularMaterial)
            case .thin:
                return AnyShapeStyle(.thinMaterial)
            case .ultraThin:
                return AnyShapeStyle(.ultraThinMaterial)
            case .thick:
                return AnyShapeStyle(.thickMaterial)
            case .ultraThick:
                return AnyShapeStyle(.ultraThickMaterial)
            }
        }
    }
    
    /// Card style options
    enum CardStyle {
        case solid
        case glass
        case outlined
        
        @ViewBuilder
        func backgroundView(cornerRadius: CGFloat) -> some View {
            switch self {
            case .solid:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
            case .glass:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            case .outlined:
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
                    )
            }
        }
    }
}

// Helper struct for shadow configuration
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// Extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Common UI Components

/// A glass morphism card component
struct GlassCard<Content: View>: View {
    var content: Content
    var cornerRadius: CGFloat = DesignSystem.BorderRadius.large
    var padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    
    init(
        cornerRadius: CGFloat = DesignSystem.BorderRadius.large,
        padding: EdgeInsets? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding ?? EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                DesignSystem.CardStyle.glass.backgroundView(cornerRadius: cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// A consistent button style
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                
                Text(title)
                    .font(DesignSystem.Typography.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.m)
            .background(DesignSystem.Colors.primaryAction)
            .foregroundColor(.white)
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .shadow(color: DesignSystem.Colors.primaryAction.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

/// A consistent section header
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    
    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.primaryText)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(DesignSystem.Typography.caption1)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DesignSystem.Spacing.m)
        .padding(.vertical, DesignSystem.Spacing.xs)
    }
} 