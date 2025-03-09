import SwiftUI

/// A modern floating tab bar with Apple-style materials
struct MaterialTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [(icon: String, title: String)]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                    
                    // Add haptic feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 22))
                            .symbolEffect(.bounce, options: .speed(1.5), value: selectedTab == index)
                            .foregroundStyle(selectedTab == index ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                            .contentTransition(.symbolEffect(.replace))
                        
                        Text(tabs[index].title)
                            .font(DesignSystem.Typography.caption2)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                            .foregroundStyle(selectedTab == index ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            .regularMaterial,
            in: Capsule()
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
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
        
        VStack {
            Spacer()
            
            MaterialTabBarPreview()
        }
    }
}

/// Preview helper for MaterialTabBar
struct MaterialTabBarPreview: View {
    @State private var selectedTab = 0
    
    var body: some View {
        MaterialTabBar(selectedTab: $selectedTab, tabs: [
            (icon: "house.fill", title: "Home"),
            (icon: "trophy.fill", title: "Challenges"),
            (icon: "chart.xyaxis.line", title: "Progress"),
            (icon: "calendar", title: "Plans"),
            (icon: "person.fill", title: "Profile")
        ])
    }
} 