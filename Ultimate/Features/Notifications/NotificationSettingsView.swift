import SwiftUI
import UserNotifications

/// View for configuring notification settings
struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var userSettings: UserSettings
    
    @State private var showingPermissionAlert = false
    @State private var showingTestNotificationConfirmation = false
    
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.l) {
                    // Header
                    notificationStatusSection
                    
                    // Task type notifications
                    taskTypeNotificationsSection
                    
                    // Quiet hours
                    quietHoursSection
                    
                    // Test notification
                    testNotificationSection
                }
                .padding()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
        } message: {
            Text("Please enable notifications in Settings to receive reminders for your challenges.")
        }
        .alert("Test Notification Sent", isPresented: $showingTestNotificationConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A test notification has been sent. You should receive it in a few seconds.")
        }
    }
    
    // MARK: - View Components
    
    /// Notification status section
    private var notificationStatusSection: some View {
        CTCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                HStack {
                    Image(systemName: notificationManager.isAuthorized ? "bell.fill" : "bell.slash.fill")
                        .font(.system(size: 24))
                        .foregroundColor(notificationManager.isAuthorized ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.accent)
                    
                    Text("Notification Status")
                        .font(DesignSystem.Typography.headline)
                    
                    Spacer()
                    
                    Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(notificationManager.isAuthorized ? DesignSystem.Colors.primaryAction : DesignSystem.Colors.accent)
                        .padding(.horizontal, DesignSystem.Spacing.s)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.BorderRadius.pill)
                                .fill(notificationManager.isAuthorized ? DesignSystem.Colors.primaryAction.opacity(0.1) : DesignSystem.Colors.accent.opacity(0.1))
                        )
                }
                
                if !notificationManager.isAuthorized {
                    Text("Enable notifications to receive reminders for your challenges and tasks.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    CTButton(
                        title: "Enable Notifications",
                        icon: "bell.badge",
                        style: .primary,
                        size: .medium
                    ) {
                        notificationManager.requestAuthorization()
                        // Check authorization status after requesting
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            UNUserNotificationCenter.current().getNotificationSettings { settings in
                                if settings.authorizationStatus != .authorized {
                                    showingPermissionAlert = true
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    /// Task type notifications section
    private var taskTypeNotificationsSection: some View {
        CTCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                Text("Task Notifications")
                    .font(DesignSystem.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: DesignSystem.Spacing.s) {
                    // Workout notifications
                    Toggle(isOn: $userSettings.notifyWorkouts) {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Image(systemName: "figure.run")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .frame(width: 24)
                            
                            Text("Workout Reminders")
                                .font(DesignSystem.Typography.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                    
                    Divider()
                    
                    // Nutrition notifications
                    Toggle(isOn: $userSettings.notifyNutrition) {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Image(systemName: "fork.knife")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .frame(width: 24)
                            
                            Text("Nutrition Reminders")
                                .font(DesignSystem.Typography.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                    
                    Divider()
                    
                    // Water notifications
                    Toggle(isOn: $userSettings.notifyWater) {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Image(systemName: "drop.fill")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .frame(width: 24)
                            
                            Text("Water Reminders")
                                .font(DesignSystem.Typography.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                    
                    Divider()
                    
                    // Reading notifications
                    Toggle(isOn: $userSettings.notifyReading) {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Image(systemName: "book.fill")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .frame(width: 24)
                            
                            Text("Reading Reminders")
                                .font(DesignSystem.Typography.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                    
                    Divider()
                    
                    // Photo notifications
                    Toggle(isOn: $userSettings.notifyPhotos) {
                        HStack(spacing: DesignSystem.Spacing.s) {
                            Image(systemName: "camera.fill")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .frame(width: 24)
                            
                            Text("Photo Reminders")
                                .font(DesignSystem.Typography.body)
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                }
            }
            .padding()
        }
        .disabled(!notificationManager.isAuthorized)
        .opacity(notificationManager.isAuthorized ? 1.0 : 0.6)
    }
    
    /// Quiet hours section
    private var quietHoursSection: some View {
        CTCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                HStack {
                    Text("Quiet Hours")
                        .font(DesignSystem.Typography.headline)
                    
                    Spacer()
                    
                    Toggle(isOn: $userSettings.quietHoursEnabled) {
                        EmptyView()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: DesignSystem.Colors.primaryAction))
                    .labelsHidden()
                }
                
                if userSettings.quietHoursEnabled {
                    VStack(spacing: DesignSystem.Spacing.m) {
                        HStack {
                            Text("Start Time")
                                .font(DesignSystem.Typography.body)
                            
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: $userSettings.quietHoursStart,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                        
                        HStack {
                            Text("End Time")
                                .font(DesignSystem.Typography.body)
                            
                            Spacer()
                            
                            DatePicker(
                                "",
                                selection: $userSettings.quietHoursEnd,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                } else {
                    Text("Enable quiet hours to prevent notifications during specific times.")
                        .font(DesignSystem.Typography.body)
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
        .disabled(!notificationManager.isAuthorized)
        .opacity(notificationManager.isAuthorized ? 1.0 : 0.6)
    }
    
    /// Test notification section
    private var testNotificationSection: some View {
        CTCard {
            VStack(spacing: DesignSystem.Spacing.m) {
                Text("Test Notifications")
                    .font(DesignSystem.Typography.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Send a test notification to verify that notifications are working correctly.")
                    .font(DesignSystem.Typography.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CTButton(
                    title: "Send Test Notification",
                    icon: "bell.badge",
                    style: .primary,
                    size: .medium
                ) {
                    notificationManager.scheduleTestNotification()
                    showingTestNotificationConfirmation = true
                }
            }
            .padding()
        }
        .disabled(!notificationManager.isAuthorized)
        .opacity(notificationManager.isAuthorized ? 1.0 : 0.6)
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NotificationSettingsView()
            .environmentObject(UserSettings())
    }
} 