import SwiftUI

/// Stat item component for displaying metrics
struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating, value: UUID())
            }
            
            Text(value)
                .font(DesignSystem.Typography.headline)
                .fontWeight(.bold)
            
            Text(label)
                .font(DesignSystem.Typography.caption1)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Challenge item component for displaying challenge cards
struct ChallengeItem: View {
    let title: String
    let progress: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .symbolEffect(.pulse, options: .repeating, value: UUID())
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(DesignSystem.Typography.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
            }
            
            Text(title)
                .font(DesignSystem.Typography.headline)
                .fontWeight(.bold)
                .foregroundColor(DesignSystem.Colors.primaryText)
                .lineLimit(1)
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(color)
        }
        .padding()
        .frame(width: 200, height: 120)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.large, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.large, style: .continuous)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.2), radius: 5, x: 0, y: 2)
    }
}

/// Detail row component for displaying information in a row
struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(color)
                .frame(width: 30)
            
            Text(label)
                .font(DesignSystem.Typography.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(DesignSystem.Colors.primaryText)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ZStack {
        PremiumBackground()
        
        VStack(spacing: 20) {
            HStack(spacing: 16) {
                StatItem(
                    value: "7,842",
                    label: "Steps",
                    icon: "figure.walk",
                    color: DesignSystem.Colors.secondaryAction
                )
                
                StatItem(
                    value: "3.2",
                    label: "Miles",
                    icon: "map",
                    color: DesignSystem.Colors.primaryAction
                )
                
                StatItem(
                    value: "284",
                    label: "Calories",
                    icon: "flame.fill",
                    color: Color(hex: "FF9500") // Orange
                )
            }
            .padding()
            .appleMaterial()
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ChallengeItem(
                        title: "30-Day Run",
                        progress: 0.4,
                        icon: "figure.run",
                        color: DesignSystem.Colors.secondaryAction
                    )
                    
                    ChallengeItem(
                        title: "Weight Loss",
                        progress: 0.7,
                        icon: "scalemass.fill",
                        color: Color(hex: "34C759") // Green
                    )
                    
                    ChallengeItem(
                        title: "Meditation",
                        progress: 0.2,
                        icon: "brain.head.profile",
                        color: Color(hex: "AF52DE") // Purple
                    )
                }
                .padding(.horizontal)
            }
            
            VStack {
                DetailRow(
                    label: "Daily Goal",
                    value: "10,000 steps",
                    icon: "figure.walk",
                    color: DesignSystem.Colors.secondaryAction
                )
                
                DetailRow(
                    label: "Current Progress",
                    value: "7,842 steps",
                    icon: "checkmark.circle",
                    color: DesignSystem.Colors.primaryAction
                )
                
                DetailRow(
                    label: "Remaining",
                    value: "2,158 steps",
                    icon: "timer",
                    color: Color(hex: "FF9500") // Orange
                )
            }
            .padding()
            .appleMaterial(style: .thin)
        }
        .padding()
    }
} 