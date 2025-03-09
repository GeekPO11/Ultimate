import SwiftUI

/// Main tab view for the app
struct MainTabView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var selectedTab = 0
    
    // App theme colors
    private let accentColor = Color.blue
    private let secondaryAccentColor = Color.purple
    private let gradientColors = [Color.blue, Color.purple, Color.indigo]
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                // Today tab
                NavigationStack {
                    TodayView()
                        .navigationTitle("Today")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Today", systemImage: "house.fill")
                }
                .tag(0)
                
                // Challenges tab
                NavigationStack {
                    ChallengesView()
                        .navigationTitle("Challenges")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Challenges", systemImage: "trophy.fill")
                }
                .tag(1)
                
                // Progress tab
                NavigationStack {
                    ProgressTrackingView()
                        .navigationTitle("Progress")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
                
                // Photos tab
                NavigationStack {
                    PhotosView()
                        .navigationTitle("Photos")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Photos", systemImage: "photo.fill")
                }
                .tag(3)
                
                // Settings tab
                NavigationStack {
                    SettingsView()
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                }
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
            }
            .safeAreaInset(edge: .bottom) {
                // Add padding at the bottom to make room for our custom floating tab bar
                Spacer().frame(height: 100)
            }
            
            // Custom floating tab bar
            HStack {
                FloatingTabItem(icon: "house.fill", title: "Today", isSelected: selectedTab == 0, 
                               selectedColor: getTabColor(for: 0)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 0
                    }
                }
                
                FloatingTabItem(icon: "trophy.fill", title: "Challenges", isSelected: selectedTab == 1,
                               selectedColor: getTabColor(for: 1)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 1
                    }
                }
                
                FloatingTabItem(icon: "chart.line.uptrend.xyaxis", title: "Progress", isSelected: selectedTab == 2,
                               selectedColor: getTabColor(for: 2)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 2
                    }
                }
                
                FloatingTabItem(icon: "photo.fill", title: "Photos", isSelected: selectedTab == 3,
                               selectedColor: getTabColor(for: 3)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 3
                    }
                }
                
                FloatingTabItem(icon: "gear", title: "Settings", isSelected: selectedTab == 4,
                               selectedColor: getTabColor(for: 4)) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = 4
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    // Base blur material
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                    
                    // Subtle gradient overlay
                    RoundedRectangle(cornerRadius: 30)
                        .fill(
                            LinearGradient(
                                colors: [
                                    gradientColors[0].opacity(0.05),
                                    gradientColors[1].opacity(0.05),
                                    gradientColors[2].opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glow effect for selected tab
                    if selectedTab >= 0 && selectedTab <= 4 {
                        Circle()
                            .fill(getTabColor(for: selectedTab))
                            .frame(width: 40, height: 40)
                            .blur(radius: 15)
                            .opacity(0.15)
                            .offset(x: getTabOffset(for: selectedTab), y: 0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 30)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: getTabColor(for: selectedTab).opacity(0.15), radius: 10, x: 0, y: 3)
            .padding(.horizontal, 24)
            .padding(.bottom, 8) // Position very close to bottom of screen
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            Logger.info("MainTabView appeared", category: .ui)
            
            // Hide the default tab bar
            UITabBar.appearance().isHidden = true
        }
    }
    
    // Get color for specific tab
    private func getTabColor(for tab: Int) -> Color {
        switch tab {
        case 0: return Color.blue // Today
        case 1: return Color.orange // Challenges
        case 2: return Color.green // Progress
        case 3: return Color.pink // Photos
        case 4: return Color.purple // Settings
        default: return accentColor
        }
    }
    
    // Calculate horizontal offset for the glow effect
    private func getTabOffset(for tab: Int) -> CGFloat {
        // Approximate the position of each tab in the HStack
        let tabWidth: CGFloat = UIScreen.main.bounds.width / 5 - 24
        let offset = CGFloat(tab) * tabWidth - UIScreen.main.bounds.width / 2 + tabWidth / 2 + 24
        return offset
    }
}

/// Custom tab item for the floating tab bar
struct FloatingTabItem: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let selectedColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: isSelected ? 22 : 20))
                    .fontWeight(isSelected ? .bold : .regular)
                    .symbolEffect(.bounce.byLayer, options: .speed(1.5), value: isSelected)
                
                Text(title)
                    .font(.system(size: 11))
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundColor(isSelected ? selectedColor : Color.secondary)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .overlay(
                isSelected ? 
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 4, height: 4)
                        .offset(y: 12)
                    : nil
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 