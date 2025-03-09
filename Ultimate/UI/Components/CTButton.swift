import SwiftUI

/// Button styles for the Challenge Tracker app
enum CTButtonStyle {
    case primary
    case secondary
    case tertiary
    case success
    case danger
    case glass
    
    // New material styles
    case regularMaterial
    case thinMaterial
    case ultraThinMaterial
    
    // Neon style
    case neon
    
    var materialStyle: DesignSystem.MaterialStyle? {
        switch self {
        case .regularMaterial: return .regular
        case .thinMaterial: return .thin
        case .ultraThinMaterial: return .ultraThin
        default: return nil
        }
    }
    
    var description: String {
        switch self {
        case .primary: return "Primary"
        case .secondary: return "Secondary"
        case .tertiary: return "Tertiary"
        case .success: return "Success"
        case .danger: return "Danger"
        case .glass: return "Glass"
        case .regularMaterial: return "Regular Material"
        case .thinMaterial: return "Thin Material"
        case .ultraThinMaterial: return "Ultra Thin Material"
        case .neon: return "Neon"
        }
    }
}

/// Button sizes for the Challenge Tracker app
enum CTButtonSize {
    case small
    case medium
    case large
    
    var description: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}

/// Custom button component for the Challenge Tracker app
struct CTButton: View {
    let title: String
    let icon: String?
    let style: CTButtonStyle
    let size: CTButtonSize
    let action: () -> Void
    let isDisabled: Bool
    let customGlassColor: Color?
    let customNeonColor: Color?
    
    // Default neon color
    private static let defaultNeonColor = Color.blue.opacity(0.8)
    
    @State private var isPressed = false
    
    init(
        title: String,
        icon: String? = nil,
        style: CTButtonStyle = .primary,
        size: CTButtonSize = .medium,
        isDisabled: Bool = false,
        customGlassColor: Color? = nil,
        customNeonColor: Color? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.size = size
        self.isDisabled = isDisabled
        self.customGlassColor = customGlassColor
        self.customNeonColor = customNeonColor
        self.action = action
        
        Logger.debug("CTButton initialized - Title: \(title), Style: \(style.description), Size: \(size.description), Disabled: \(isDisabled)", category: .ui)
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                Logger.info("CTButton tapped - \(title)", category: .ui)
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isPressed = false
                    }
                    action()
                }
            } else {
                Logger.debug("CTButton tap ignored (disabled) - \(title)", category: .ui)
            }
        }) {
            buttonContent
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isDisabled ? 0.6 : 1.0)
        .scaleEffect(isPressed ? 0.97 : 1.0)
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(iconFont)
                    .symbolEffect(.bounce, options: .speed(1.5), value: isPressed)
            }
            
            Text(title)
                .font(textFont)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(height: height)
        .frame(maxWidth: size == .large ? .infinity : nil)
        .background(backgroundView)
        .foregroundColor(foregroundColor)
        .cornerRadius(DesignSystem.BorderRadius.medium)
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        if let materialStyle = style.materialStyle {
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                .fill(materialStyle == .ultraThin ? .ultraThinMaterial : 
                      materialStyle == .thin ? .thinMaterial : .regularMaterial)
        } else if style == .neon {
            // Neon style with transparent background and glowing border
            ZStack {
                // Transparent background
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .fill(Color.clear)
                
                // Glowing border
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                    .strokeBorder(foregroundColor, lineWidth: 1.5)
                    .shadow(color: foregroundColor, radius: 4, x: 0, y: 0)
                    .shadow(color: foregroundColor.opacity(0.7), radius: 8, x: 0, y: 0)
            }
        } else {
            // Apply glass effect to all buttons
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                .fill(.ultraThinMaterial)
                .overlay(backgroundColor.opacity(0.6))
        }
    }
    
    // MARK: - Computed Properties
    
    @ViewBuilder
    private var backgroundColor: some View {
        switch style {
        case .primary:
            DesignSystem.Colors.primaryAction
        case .secondary:
            DesignSystem.Colors.secondaryAction
        case .tertiary:
            DesignSystem.Colors.cardBackground
        case .success:
            Color(hex: "34C759") // Green
        case .danger:
            Color(hex: "FF3B30") // Red
        case .glass:
            DesignSystem.Colors.cardBackground.opacity(0.3)
        case .neon:
            Color.clear
        default:
            DesignSystem.Colors.cardBackground
        }
    }
    
    private var foregroundColor: Color {
        if let _ = style.materialStyle {
            return .primary
        }
        
        switch style {
        case .primary, .success, .danger:
            return .white
        case .secondary:
            return .white
        case .tertiary, .glass:
            return DesignSystem.Colors.primaryText
        case .neon:
            return customNeonColor ?? CTButton.defaultNeonColor
        default:
            return .primary
        }
    }
    
    private var height: CGFloat {
        switch size {
        case .small:
            return 36
        case .medium:
            return 44
        case .large:
            return 56
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small:
            return DesignSystem.Spacing.s
        case .medium:
            return DesignSystem.Spacing.m
        case .large:
            return DesignSystem.Spacing.l
        }
    }
    
    private var verticalPadding: CGFloat {
        switch size {
        case .small:
            return DesignSystem.Spacing.xxs
        case .medium:
            return DesignSystem.Spacing.xs
        case .large:
            return DesignSystem.Spacing.s
        }
    }
    
    private var textFont: Font {
        switch size {
        case .small:
            return DesignSystem.Typography.footnote
        case .medium:
            return DesignSystem.Typography.body
        case .large:
            return DesignSystem.Typography.headline
        }
    }
    
    private var iconFont: Font {
        switch size {
        case .small:
            return .system(size: 14)
        case .medium:
            return .system(size: 16)
        case .large:
            return .system(size: 20)
        }
    }
}

/// A floating action button component
struct CTFloatingActionButton: View {
    let icon: String
    let action: () -> Void
    let color: Color
    
    @State private var isPressed = false
    
    init(
        icon: String,
        color: Color = DesignSystem.Colors.primaryAction,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.color = color
        self.action = action
        
        Logger.debug("CTFloatingActionButton initialized - Icon: \(icon)", category: .ui)
    }
    
    var body: some View {
        Button(action: {
            Logger.info("CTFloatingActionButton tapped - \(icon)", category: .ui)
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isPressed = true
            }
            
            // Add haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = false
                }
                action()
            }
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                color,
                                color.opacity(0.9)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(
                        color: color.opacity(isPressed ? 0.2 : 0.3),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                    .symbolEffect(.bounce, options: .speed(1.5), value: isPressed)
            }
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Extension for Conditional Modifiers
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Previews
struct CTButton_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                Group {
                    CTButton(title: "Primary Button", icon: "star.fill", style: .primary) {}
                    CTButton(title: "Secondary Button", icon: "heart.fill", style: .secondary) {}
                    CTButton(title: "Tertiary Button", icon: "hand.thumbsup.fill", style: .tertiary) {}
                    CTButton(title: "Success Button", icon: "checkmark.circle.fill", style: .success) {}
                    CTButton(title: "Danger Button", icon: "xmark.circle.fill", style: .danger) {}
                    CTButton(title: "Glass Button", icon: "sparkles", style: .glass) {}
                }
                
                Group {
                    CTButton(title: "Regular Material", icon: "star.fill", style: .regularMaterial) {}
                    CTButton(title: "Thin Material", icon: "heart.fill", style: .thinMaterial) {}
                    CTButton(title: "Ultra Thin Material", icon: "sparkles", style: .ultraThinMaterial) {}
                }
                
                // Neon Buttons
                Group {
                    Text("Neon Buttons")
                        .font(.headline)
                        .padding(.top)
                    
                    CTButton(
                        title: "Blue Neon",
                        icon: "sparkles",
                        style: .neon,
                        action: {}
                    )
                    
                    CTButton(
                        title: "Green Neon",
                        icon: "sparkles",
                        style: .neon,
                        customNeonColor: Color.green.opacity(0.8),
                        action: {}
                    )
                    
                    CTButton(
                        title: "Pink Neon",
                        icon: "sparkles",
                        style: .neon,
                        customNeonColor: Color.pink.opacity(0.8),
                        action: {}
                    )
                    
                    CTButton(
                        title: "Purple Neon",
                        icon: "sparkles",
                        style: .neon,
                        customNeonColor: Color.purple.opacity(0.8),
                        action: {}
                    )
                }
            }
            .padding()
        }
        .preferredColorScheme(.dark)
        .background(DesignSystem.Colors.background)
    }
} 