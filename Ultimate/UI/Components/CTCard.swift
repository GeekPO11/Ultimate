import SwiftUI

/// Card elevation levels for the Challenge Tracker app
enum CTCardElevation {
    case level1
    case level2
    case level3
    case level4
    
    var shadow: Shadow {
        switch self {
        case .level1:
            return DesignSystem.Elevation.level1
        case .level2:
            return DesignSystem.Elevation.level2
        case .level3:
            return DesignSystem.Elevation.level3
        case .level4:
            return DesignSystem.Elevation.level4
        }
    }
    
    var description: String {
        switch self {
        case .level1: return "Level 1"
        case .level2: return "Level 2"
        case .level3: return "Level 3"
        case .level4: return "Level 4"
        }
    }
}

/// Card style options for the Challenge Tracker app
enum CTCardStyle {
    case standard
    case gradient
    case glass
    case bordered
    case highlight
    
    // New material styles
    case regularMaterial
    case thinMaterial
    case ultraThinMaterial
    case thickMaterial
    case ultraThickMaterial
    
    var materialStyle: DesignSystem.MaterialStyle? {
        switch self {
        case .regularMaterial: return .regular
        case .thinMaterial: return .thin
        case .ultraThinMaterial: return .ultraThin
        case .thickMaterial: return .thick
        case .ultraThickMaterial: return .ultraThick
        default: return nil
        }
    }
    
    var description: String {
        switch self {
        case .standard: return "Standard"
        case .gradient: return "Gradient"
        case .glass: return "Glass"
        case .bordered: return "Bordered"
        case .highlight: return "Highlight"
        case .regularMaterial: return "Regular Material"
        case .thinMaterial: return "Thin Material"
        case .ultraThinMaterial: return "Ultra Thin Material"
        case .thickMaterial: return "Thick Material"
        case .ultraThickMaterial: return "Ultra Thick Material"
        }
    }
}

/// Custom card component for the Challenge Tracker app
struct CTCard<Content: View>: View {
    let elevation: CTCardElevation
    let style: CTCardStyle
    let content: Content
    let cornerRadius: CGFloat
    let padding: EdgeInsets
    
    init(
        elevation: CTCardElevation = .level1,
        style: CTCardStyle = .standard,
        cornerRadius: CGFloat = DesignSystem.BorderRadius.medium,
        padding: EdgeInsets? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.elevation = elevation
        self.style = style
        self.content = content()
        self.cornerRadius = cornerRadius
        self.padding = padding ?? EdgeInsets(
            top: DesignSystem.Spacing.m,
            leading: DesignSystem.Spacing.m,
            bottom: DesignSystem.Spacing.m,
            trailing: DesignSystem.Spacing.m
        )
        
        Logger.debug("CTCard initialized - Style: \(style.description), Elevation: \(elevation.description)", category: .ui)
    }
    
    var body: some View {
        if let materialStyle = style.materialStyle {
            // Use the new material style
            content
                .padding(padding)
                .modifier(UIMaterial(style: materialStyle, cornerRadius: cornerRadius))
                .onAppear {
                    Logger.debug("CTCard appeared with material style: \(style.description)", category: .ui)
                }
        } else {
            // Use the legacy styles
            cardBackground
                .cornerRadius(cornerRadius)
                .shadow(color: elevation.shadow.color, radius: elevation.shadow.radius, x: elevation.shadow.x, y: elevation.shadow.y)
                .onAppear {
                    Logger.debug("CTCard appeared with style: \(style.description)", category: .ui)
                }
        }
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .standard:
            standardCard
        case .gradient:
            gradientCard
        case .glass:
            glassCard
        case .bordered:
            borderedCard
        case .highlight:
            highlightCard
        default:
            standardCard // Fallback for material styles (should not be reached)
        }
    }
    
    private var standardCard: some View {
        content
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
    }
    
    private var gradientCard: some View {
        content
            .padding(padding)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        DesignSystem.Colors.primaryAction.opacity(0.8),
                        DesignSystem.Colors.secondaryAction.opacity(0.6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var glassCard: some View {
        content
            .padding(padding)
            .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: cornerRadius))
    }
    
    private var borderedCard: some View {
        content
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DesignSystem.Colors.dividers, lineWidth: 1)
            )
    }
    
    private var highlightCard: some View {
        content
            .padding(padding)
            .background(DesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(DesignSystem.Colors.accent, lineWidth: 2)
            )
    }
}

/// A visual effect view for UIKit blur effects
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    
    func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) {
        uiView.effect = effect
    }
}

/// A card component specifically designed for challenge items
struct CTChallengeCard: View {
    let title: String
    let description: String
    let progress: Double
    let image: String?
    let onTap: () -> Void
    let style: CTCardStyle
    
    // Add state to track if image is loaded
    @State private var imageLoaded: Bool = false
    
    init(
        title: String,
        description: String,
        progress: Double,
        image: String? = nil,
        style: CTCardStyle = .gradient,
        onTap: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.progress = progress
        self.image = image
        self.style = style
        self.onTap = onTap
        
        Logger.debug("CTChallengeCard initialized - Title: \(title), Image: \(image ?? "nil"), Progress: \(Int(progress * 100))%", category: .ui)
    }
    
    var body: some View {
        CTCard(elevation: .level2, style: style) {
            Button(action: {
                Logger.info("Challenge card tapped - \(title)", category: .challenges)
                onTap()
            }) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    // Header with image if available
                    if let imageName = image {
                        ZStack(alignment: .bottomLeading) {
                            // Use a placeholder while image is loading
                            if !imageLoaded {
                                Rectangle()
                                    .fill(DesignSystem.Colors.cardBackground)
                                    .frame(height: 120)
                                    .cornerRadius(DesignSystem.BorderRadius.small)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                    )
                            }
                            
                            Image(imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 120)
                                .clipped()
                                .cornerRadius(DesignSystem.BorderRadius.small)
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .clear,
                                            .black.opacity(0.3)
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                    .cornerRadius(DesignSystem.BorderRadius.small)
                                )
                                .onAppear {
                                    Logger.debug("Challenge card image appeared - \(title)", category: .ui)
                                    imageLoaded = true
                                }
                            
                            // Progress indicator on the image
                            HStack(spacing: DesignSystem.Spacing.xxs) {
                                Text("\(Int(progress * 100))%")
                                    .font(DesignSystem.Typography.caption1)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                CTProgressRing(progress: progress, color: .white, lineWidth: 3, size: 20)
                            }
                            .padding(DesignSystem.Spacing.xs)
                            .background(DesignSystem.Colors.primaryAction.opacity(0.8))
                            .cornerRadius(DesignSystem.BorderRadius.pill)
                            .padding(DesignSystem.Spacing.xs)
                        }
                    }
                    
                    // Title and description
                    Text(title)
                        .font(DesignSystem.Typography.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Text(description)
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                    
                    // Progress bar (only show if no image)
                    if image == nil {
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                            HStack {
                                Text("Progress")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.secondaryText)
                                
                                Spacer()
                                
                                Text("\(Int(progress * 100))%")
                                    .font(DesignSystem.Typography.caption1)
                                    .foregroundColor(DesignSystem.Colors.primaryAction)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                                        .fill(DesignSystem.Colors.dividers)
                                        .frame(height: 8)
                                    
                                    // Progress
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.small)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    DesignSystem.Colors.primaryAction,
                                                    DesignSystem.Colors.primaryAction.opacity(0.8)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * progress, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                }
                .onAppear {
                    Logger.debug("Challenge card content appeared - \(title)", category: .ui)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .onAppear {
            Logger.info("Challenge card appeared - \(title) with \(Int(progress * 100))% progress", category: .challenges)
        }
    }
}

// MARK: - Extensions

#Preview {
    VStack(spacing: DesignSystem.Spacing.m) {
        CTChallengeCard(
            title: "75 Hard Challenge",
            description: "Transform your life with this intense 75-day mental toughness program.",
            progress: 0.45
        ) {
            Logger.info("75 Hard Challenge card tapped in preview", category: .ui)
        }
        
        CTCard(style: .glass) {
            Text("Glass Card Style")
                .font(DesignSystem.Typography.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
        
        CTCard(style: .highlight) {
            Text("Highlight Card Style")
                .font(DesignSystem.Typography.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        }
    }
    .padding()
    .background(DesignSystem.Colors.background)
}

// MARK: - Previews

struct CTCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            // Background that shows off the glass effect
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        previewCard(title: "Standard Card", style: .standard)
                        previewCard(title: "Gradient Card", style: .gradient)
                        previewCard(title: "Glass Card", style: .glass)
                        previewCard(title: "Bordered Card", style: .bordered)
                        previewCard(title: "Highlight Card", style: .highlight)
                    }
                    
                    Group {
                        previewCard(title: "Regular Material", style: .regularMaterial)
                        previewCard(title: "Thin Material", style: .thinMaterial)
                        previewCard(title: "Ultra Thin Material", style: .ultraThinMaterial)
                        previewCard(title: "Thick Material", style: .thickMaterial)
                        previewCard(title: "Ultra Thick Material", style: .ultraThickMaterial)
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.light)
        .previewDisplayName("Light Mode")
        
        ZStack {
            // Background that shows off the glass effect
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        previewCard(title: "Standard Card", style: .standard)
                        previewCard(title: "Gradient Card", style: .gradient)
                        previewCard(title: "Glass Card", style: .glass)
                        previewCard(title: "Bordered Card", style: .bordered)
                        previewCard(title: "Highlight Card", style: .highlight)
                    }
                    
                    Group {
                        previewCard(title: "Regular Material", style: .regularMaterial)
                        previewCard(title: "Thin Material", style: .thinMaterial)
                        previewCard(title: "Ultra Thin Material", style: .ultraThinMaterial)
                        previewCard(title: "Thick Material", style: .thickMaterial)
                        previewCard(title: "Ultra Thick Material", style: .ultraThickMaterial)
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .previewDisplayName("Dark Mode")
    }
    
    static func previewCard(title: String, style: CTCardStyle) -> some View {
        CTCard(style: style) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                
                Text("This is a preview of the \(title) style")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
} 