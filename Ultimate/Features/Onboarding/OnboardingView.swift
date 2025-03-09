import SwiftUI
import SwiftData
import UserNotifications

/// Onboarding view for first-time users
struct OnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    
    // Define onboarding pages with more appealing colors
    let pages = [
        OnboardingPage(
            title: "Welcome to Ultimate",
            description: "Your personal assistant for tracking progress, managing tasks, and achieving your goals.",
            imageName: "figure.mind.and.body",
            backgroundColor: DesignSystem.Colors.neonBlue
        ),
        OnboardingPage(
            title: "Track Your Progress",
            description: "Monitor your daily achievements and visualize your journey towards success.",
            imageName: "chart.line.uptrend.xyaxis",
            backgroundColor: DesignSystem.Colors.neonGreen
        ),
        OnboardingPage(
            title: "Capture Moments",
            description: "Save photos of your journey to stay motivated and celebrate your milestones.",
            imageName: "photo.on.rectangle",
            backgroundColor: DesignSystem.Colors.neonCyan
        ),
        OnboardingPage(
            title: "Ready to Begin?",
            description: "Start your journey to a better you today!",
            imageName: "star.fill",
            backgroundColor: DesignSystem.Colors.neonPurple
        )
    ]
    
    // Function to complete onboarding and update app state
    func completeOnboarding() {
        Logger.info("Completing onboarding...", category: .ui)
        
        // Create a default user if not already created
        createDefaultUser()
        
        // Update user settings
        userSettings.completeOnboarding()
        Logger.info("UserSettings updated: onboarding completed", category: .ui)
        
        // Force update the app state with a slight delay to ensure everything is processed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            Logger.info("Posting onboarding completed notification...", category: .ui)
            NotificationCenter.default.post(name: NSNotification.Name("OnboardingCompleted"), object: nil)
            Logger.info("Onboarding completed notification posted", category: .ui)
            
            // Try to dismiss if possible (for modal presentations)
            self.dismiss()
        }
    }
    
    // Function to create a default user
    func createDefaultUser() {
        Logger.info("Creating default user...", category: .ui)
        
        // Check if a user already exists
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? modelContext.fetch(descriptor)) ?? []
        
        if existingUsers.isEmpty {
            // Create a default user
            let user = User(
                name: "User",
                appearancePreference: "System",
                hasCompletedOnboarding: true
            )
            
            // Insert the user into the model context
            modelContext.insert(user)
            
            // Save changes
            do {
                try modelContext.save()
                Logger.info("Default user created successfully", category: .ui)
            } catch {
                Logger.error("Error saving default user: \(error)", category: .ui)
            }
        } else {
            // Update existing user
            let user = existingUsers[0]
            user.hasCompletedOnboarding = true
            
            do {
                try modelContext.save()
                Logger.info("Existing user updated: onboarding completed", category: .ui)
            } catch {
                Logger.error("Error updating existing user: \(error)", category: .ui)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Premium glass background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    currentPage < pages.count ? pages[currentPage].backgroundColor.opacity(0.5) : DesignSystem.Colors.neonPurple.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            .animation(.easeInOut(duration: 0.5), value: currentPage)
            
            // Animated background elements
            ZStack {
                // Blurred circles for premium look
                ForEach(0..<5) { index in
                    Circle()
                        .fill(currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple)
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .blur(radius: 60)
                        .opacity(0.4)
                }
            }
            .animation(.easeInOut(duration: 0.8), value: currentPage)
            
            if currentPage < pages.count {
                VStack {
                    // Skip button
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            Logger.info("Skip button tapped", category: .ui)
                            withAnimation {
                                currentPage = pages.count
                            }
                        }) {
                            Text("Skip")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.3))
                                .cornerRadius(DesignSystem.BorderRadius.pill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.pill)
                                        .strokeBorder(currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple, lineWidth: 1.5)
                                        .shadow(color: currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple, radius: 3, x: 0, y: 0)
                                )
                        }
                    }
                    .padding(.horizontal)
                    
                    // Page content with swipe gesture
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            OnboardingPageView(page: pages[index])
                                .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentPage)
                    .transition(.opacity)
                    .gesture(
                        DragGesture()
                            .onEnded { gesture in
                                let threshold: CGFloat = 50
                                if gesture.translation.width > threshold {
                                    // Swiped right
                                    withAnimation {
                                        currentPage = max(0, currentPage - 1)
                                    }
                                } else if gesture.translation.width < -threshold {
                                    // Swiped left
                                    withAnimation {
                                        currentPage = min(pages.count - 1, currentPage + 1)
                                    }
                                }
                            }
                    )
                    
                    // Page indicators and buttons
                    VStack {
                        // Page indicators
                        HStack(spacing: 10) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(currentPage == index ? (currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple) : Color.white.opacity(0.4))
                                    .frame(width: 10, height: 10)
                                    .shadow(color: currentPage == index ? (currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple) : Color.clear, radius: 3)
                                    .onTapGesture {
                                        withAnimation {
                                            currentPage = index
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 20)
                        
                        // Navigation buttons
                        HStack {
                            // Back button
                            if currentPage > 0 {
                                Button(action: {
                                    withAnimation {
                                        currentPage -= 1
                                    }
                                }) {
                                    HStack(spacing: DesignSystem.Spacing.xs) {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                    .font(DesignSystem.Typography.body.weight(.medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, DesignSystem.Spacing.m)
                                    .padding(.vertical, DesignSystem.Spacing.s)
                                    .background(Color.black.opacity(0.3))
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule()
                                            .strokeBorder(currentPage > 0 && max(currentPage - 1, 0) < pages.count ? pages[max(currentPage - 1, 0)].backgroundColor : DesignSystem.Colors.neonPurple, lineWidth: 1.5)
                                            .shadow(color: currentPage > 0 && max(currentPage - 1, 0) < pages.count ? pages[max(currentPage - 1, 0)].backgroundColor : DesignSystem.Colors.neonPurple, radius: 3, x: 0, y: 0)
                                    )
                                }
                            } else {
                                Spacer()
                            }
                            
                            Spacer()
                            
                            // Next/Get Started button with improved styling
                            Button(action: {
                                if currentPage < pages.count - 1 {
                                    withAnimation {
                                        currentPage += 1
                                    }
                                } else {
                                    withAnimation {
                                        currentPage = pages.count
                                    }
                                }
                            }) {
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Text(currentPage < pages.count - 1 ? "Next" : "Continue")
                                    Image(systemName: "chevron.right")
                                }
                                .font(DesignSystem.Typography.body.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, DesignSystem.Spacing.m)
                                .padding(.vertical, DesignSystem.Spacing.s)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .strokeBorder(currentPage < pages.count - 1 && min(currentPage + 1, pages.count - 1) < pages.count ? pages[min(currentPage + 1, pages.count - 1)].backgroundColor : (currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple), lineWidth: 1.5)
                                        .shadow(color: currentPage < pages.count - 1 && min(currentPage + 1, pages.count - 1) < pages.count ? pages[min(currentPage + 1, pages.count - 1)].backgroundColor : (currentPage < pages.count ? pages[currentPage].backgroundColor : DesignSystem.Colors.neonPurple), radius: 3, x: 0, y: 0)
                                )
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.l)
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
                .transition(.opacity)
            } else {
                // User setup view (final step)
                UserSetupView(onComplete: completeOnboarding)
                    .transition(.opacity)
                    .zIndex(1) // Ensure this view is on top during transitions
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentPage >= pages.count)
        .onAppear {
            // Set up notification observer for app state changes
            NotificationCenter.default.addObserver(forName: NSNotification.Name("OnboardingCompleted"), object: nil, queue: .main) { _ in
                // This will be handled by the app's state management
            }
        }
    }
}

/// Model for onboarding page content
struct OnboardingPage {
    let title: String
    let description: String
    let imageName: String
    let backgroundColor: Color
}

/// View for displaying an onboarding page
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()
            
            // Image
            if UIImage(named: page.imageName) != nil {
                Image(page.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 250)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
            } else {
                // Fallback to system image
                Image(systemName: page.imageName)
                    .font(.system(size: 100))
                    .foregroundColor(page.backgroundColor)
                    .frame(height: 250)
                    .shadow(color: page.backgroundColor.opacity(0.6), radius: 10, x: 0, y: 5)
            }
            
            // Text content in glass card
            VStack(spacing: DesignSystem.Spacing.m) {
                Text(page.title)
                    .font(DesignSystem.Typography.title1)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }
            .padding(DesignSystem.Spacing.l)
            .background(.ultraThinMaterial)
            .cornerRadius(DesignSystem.BorderRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.large)
                    .strokeBorder(page.backgroundColor.opacity(0.7), lineWidth: 1.5)
                    .shadow(color: page.backgroundColor.opacity(0.5), radius: 5, x: 0, y: 0)
            )
            .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
            .padding(.horizontal, DesignSystem.Spacing.l)
            
            Spacer()
            Spacer()
        }
        .padding()
    }
}

/// View for user setup (final onboarding page)
struct UserSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    let onComplete: () -> Void
    
    @State private var name = ""
    @State private var notificationsEnabled = false
    @State private var isRequestingPermission = false
    
    var body: some View {
        ZStack {
            // Premium glass background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black.opacity(0.8),
                    DesignSystem.Colors.neonPurple.opacity(0.5)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Animated background elements
            ZStack {
                // Blurred circles for premium look
                ForEach(0..<5) { index in
                    Circle()
                        .fill(DesignSystem.Colors.neonPurple)
                        .frame(width: CGFloat.random(in: 100...300))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .blur(radius: 60)
                        .opacity(0.4)
                }
            }
            
            VStack(spacing: DesignSystem.Spacing.xl) {
                Spacer()
                
                // Header
                VStack(spacing: DesignSystem.Spacing.m) {
                    Text("Let's Set Up Your Profile")
                        .font(DesignSystem.Typography.title1)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Personalize your experience to get the most out of Ultimate.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                }
                
                // Form
                VStack(spacing: DesignSystem.Spacing.l) {
                    // Name field
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Your Name")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(.white)
                        
                        TextField("Enter your name", text: $name)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .stroke(DesignSystem.Colors.neonPurple.opacity(0.7), lineWidth: 1.5)
                                    .shadow(color: DesignSystem.Colors.neonPurple.opacity(0.5), radius: 3, x: 0, y: 0)
                            )
                            .foregroundColor(.white)
                    }
                    
                    // Notifications permission
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                        Text("Stay Updated")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(.white)
                        
                        Text("Enable notifications to get reminders about your daily tasks and challenges.")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, DesignSystem.Spacing.xs)
                        
                        Button(action: {
                            requestNotificationPermission()
                        }) {
                            HStack {
                                Image(systemName: notificationsEnabled ? "bell.fill" : "bell")
                                    .foregroundColor(notificationsEnabled ? DesignSystem.Colors.neonGreen : .white)
                                
                                Text(notificationsEnabled ? "Notifications Enabled" : "Enable Notifications")
                                    .font(DesignSystem.Typography.callout)
                                
                                Spacer()
                                
                                if isRequestingPermission {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(DesignSystem.BorderRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.medium)
                                    .stroke(notificationsEnabled ? DesignSystem.Colors.neonGreen.opacity(0.7) : DesignSystem.Colors.neonPurple.opacity(0.7), lineWidth: 1.5)
                                    .shadow(color: notificationsEnabled ? DesignSystem.Colors.neonGreen.opacity(0.5) : DesignSystem.Colors.neonPurple.opacity(0.5), radius: 3, x: 0, y: 0)
                            )
                        }
                        .disabled(isRequestingPermission)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                
                Spacer()
                
                // Get started button
                Button(action: {
                    // Save user settings
                    createUser()
                    
                    // Complete onboarding
                    onComplete()
                }) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Get Started")
                        Image(systemName: "checkmark")
                    }
                    .font(DesignSystem.Typography.body.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, DesignSystem.Spacing.m)
                    .padding(.vertical, DesignSystem.Spacing.s)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(DesignSystem.Colors.neonPurple, lineWidth: 1.5)
                            .shadow(color: DesignSystem.Colors.neonPurple, radius: 3, x: 0, y: 0)
                    )
                }
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .padding(.bottom, DesignSystem.Spacing.xl)
            }
        }
        .onAppear {
            checkNotificationStatus()
        }
    }
    
    private func requestNotificationPermission() {
        isRequestingPermission = true
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                isRequestingPermission = false
                notificationsEnabled = granted
                
                if granted {
                    Logger.info("Notification permission granted, enabling all notifications", category: .notification)
                    // Enable all notifications in the app
                    NotificationManager.shared.enableAllNotifications(userSettings: userSettings)
                    
                    // Register for remote notifications (for push notifications)
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                } else if let error = error {
                    Logger.error("Error requesting notification permission: \(error.localizedDescription)", category: .notification)
                } else {
                    Logger.warning("Notification permission denied by user", category: .notification)
                }
            }
        }
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                notificationsEnabled = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
            }
        }
    }
    
    private func createUser() {
        Logger.info("Creating user with name: \(name)", category: .ui)
        
        // Check if a user already exists
        let descriptor = FetchDescriptor<User>()
        let existingUsers = (try? modelContext.fetch(descriptor)) ?? []
        
        if existingUsers.isEmpty {
            // Create a default user
            let user = User(
                name: name.isEmpty ? "User" : name,
                appearancePreference: "System",
                hasCompletedOnboarding: true
            )
            
            // Insert the user into the model context
            modelContext.insert(user)
            
            // Save changes
            do {
                try modelContext.save()
                Logger.info("User created successfully with name: \(user.name)", category: .ui)
            } catch {
                Logger.error("Error saving user: \(error)", category: .ui)
            }
        } else {
            // Update existing user
            let user = existingUsers[0]
            user.name = name.isEmpty ? "User" : name
            user.hasCompletedOnboarding = true
            
            do {
                try modelContext.save()
                Logger.info("Existing user updated with name: \(user.name)", category: .ui)
            } catch {
                Logger.error("Error updating existing user: \(error)", category: .ui)
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(UserSettings())
        .modelContainer(for: [User.self, Challenge.self, Task.self, DailyTask.self, ProgressPhoto.self], inMemory: true)
} 