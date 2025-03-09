import SwiftUI

/// Custom progress ring component for the Challenge Tracker app
struct CTProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let size: CGFloat
    let showGlassBackground: Bool
    
    init(
        progress: Double,
        color: Color = DesignSystem.Colors.primaryAction,
        lineWidth: CGFloat = 10,
        size: CGFloat = 100,
        showGlassBackground: Bool = false
    ) {
        self.progress = min(max(progress, 0), 1) // Ensure progress is between 0 and 1
        self.color = color
        self.lineWidth = lineWidth
        self.size = size
        self.showGlassBackground = showGlassBackground
    }
    
    var body: some View {
        ZStack {
            if showGlassBackground {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                    )
            }
            
            // Background circle
            Circle()
                .stroke(
                    color.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90)) // Start from top
                .animation(.easeInOut, value: progress)
            
            // Percentage text
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .frame(width: size, height: size)
    }
}

/// A multi-ring progress component for tracking multiple metrics
struct CTMultiProgressRing: View {
    struct RingData {
        let progress: Double
        let color: Color
        let title: String
        
        init(progress: Double, color: Color, title: String) {
            self.progress = progress
            self.color = color
            self.title = title
        }
    }
    
    let rings: [RingData]
    let size: CGFloat
    let showGlassBackground: Bool
    
    init(rings: [RingData], size: CGFloat = 150, showGlassBackground: Bool = false) {
        self.rings = rings
        self.size = size
        self.showGlassBackground = showGlassBackground
    }
    
    var body: some View {
        ZStack {
            // Create multiple rings with different sizes
            ForEach(0..<rings.count, id: \.self) { index in
                let ringIndex = rings.count - 1 - index // Reverse order so largest ring is at the back
                let ring = rings[ringIndex]
                let ringSize = size - (CGFloat(index) * (size * 0.15))
                let lineWidth = size * 0.05
                
                CTProgressRing(
                    progress: ring.progress,
                    color: ring.color,
                    lineWidth: lineWidth,
                    size: ringSize,
                    showGlassBackground: index == 0 && showGlassBackground
                )
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottom) {
            // Legend
            HStack(spacing: DesignSystem.Spacing.m) {
                ForEach(0..<rings.count, id: \.self) { index in
                    let ring = rings[index]
                    
                    HStack(spacing: DesignSystem.Spacing.xxs) {
                        Circle()
                            .fill(ring.color)
                            .frame(width: 8, height: 8)
                        
                        Text(ring.title)
                            .font(DesignSystem.Typography.caption2)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.s)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(DesignSystem.Colors.cardBackground.opacity(0.8))
            .cornerRadius(DesignSystem.BorderRadius.small)
            .offset(y: size * 0.1)
        }
    }
}

/// A modern circular progress indicator with glass morphism
struct GlassProgressCircle: View {
    let progress: Double
    let size: CGFloat
    let lineWidth: CGFloat
    let colors: [Color]
    let icon: String?
    let label: String?
    
    init(
        progress: Double,
        size: CGFloat = 120,
        lineWidth: CGFloat = 10,
        colors: [Color] = [.blue, .cyan],
        icon: String? = nil,
        label: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.colors = colors
        self.icon = icon
        self.label = label
    }
    
    var body: some View {
        ZStack {
            // Glass background
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
            
            // Background track
            Circle()
                .stroke(
                    Color.secondary.opacity(0.2),
                    lineWidth: lineWidth
                )
            
            // Progress circle with gradient
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    LinearGradient(
                        colors: colors,
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)
            
            // Center content
            VStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: size * 0.2))
                        .foregroundStyle(
                            LinearGradient(
                                colors: colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size * 0.2, weight: .bold, design: .rounded))
                
                if let label = label {
                    Text(label)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        // Background that shows off the glass effect
        LinearGradient(
            colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        VStack(spacing: 40) {
            CTProgressRing(progress: 0.75)
            
            CTProgressRing(progress: 0.65, color: .blue, showGlassBackground: true)
            
            CTMultiProgressRing(rings: [
                CTMultiProgressRing.RingData(progress: 0.8, color: DesignSystem.Colors.primaryAction, title: "Workouts"),
                CTMultiProgressRing.RingData(progress: 0.6, color: DesignSystem.Colors.secondaryAction, title: "Water"),
                CTMultiProgressRing.RingData(progress: 0.4, color: DesignSystem.Colors.accent, title: "Reading")
            ], showGlassBackground: true)
            
            HStack(spacing: 20) {
                GlassProgressCircle(
                    progress: 0.75,
                    colors: [.blue, .cyan],
                    icon: "figure.walk",
                    label: "Steps"
                )
                
                GlassProgressCircle(
                    progress: 0.45,
                    colors: [.green, .mint],
                    icon: "heart.fill",
                    label: "Health"
                )
                
                GlassProgressCircle(
                    progress: 0.9,
                    colors: [.orange, .red],
                    icon: "flame.fill",
                    label: "Calories"
                )
            }
        }
        .padding()
    }
} 