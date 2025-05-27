import SwiftUI
import SwiftData
import PhotosUI
import StoreKit

/// Main settings view
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @EnvironmentObject private var userSettings: UserSettings
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var enableDetailedLogging: Bool = UserDefaults.standard.bool(forKey: "enableDetailedLogging")
    
    var user: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            SettingsContentView()
                .environmentObject(userSettings)
                .environmentObject(notificationManager)
                .environment(\.modelContext, modelContext)
        }
        .onAppear {
            Logger.info("SettingsView appeared", category: .settings)
            notificationManager.checkAuthorizationStatus()
        }
    }
    
    private func resetOnboarding() {
        Logger.info("Resetting onboarding experience", category: .settings)
        userSettings.resetOnboarding()
    }
}

/// Content view for settings to break up the complex expression
struct SettingsContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @EnvironmentObject private var userSettings: UserSettings
    @EnvironmentObject private var notificationManager: NotificationManager
    @State private var enableDetailedLogging: Bool = UserDefaults.standard.bool(forKey: "enableDetailedLogging")
    @State private var showResetConfirmation: Bool = false
    
    var user: User? {
        users.first
    }
    
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.m) {
                    // Profile section
                    profileSection
                    
                    // Appearance section
                    appearanceSection
                    
                    // Notifications section
                    notificationsSection
                    
                    // Logging section
                    loggingSection
                    
                    // About section
                    aboutSection
                    
                    // Reset onboarding section
                    resetOnboardingSection
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Settings")
    }
    
    // MARK: - Section Views
    
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Profile")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal)
            
                    if let user = user {
                        NavigationLink(destination: EditProfileView(user: user)) {
                            HStack {
                                Image(systemName: "person.circle")
                                    .foregroundColor(DesignSystem.Colors.primaryAction)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(user.name)
                                        .font(.headline)
                                .foregroundColor(DesignSystem.Colors.primaryText)
                                    
                                    if let email = user.email {
                                        Text(email)
                                            .font(.subheadline)
                                            .foregroundColor(DesignSystem.Colors.secondaryText)
                                    }
                                }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(.caption)
                    }
                    .padding()
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .padding(.horizontal)
                        }
                    } else {
                        Text("No user profile found")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .padding(.horizontal)
            }
        }
    }
    
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Appearance")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal)
            
            VStack {
                HStack {
                    Text("Theme")
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Picker("Theme", selection: $userSettings.selectedAppearance) {
                        ForEach(AppearancePreference.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: userSettings.selectedAppearance) { _, newValue in
                        Logger.info("Appearance preference changed to: \(newValue.rawValue)", category: .settings)
                        if let user = user {
                            user.updateAppearancePreference(newValue.rawValue)
                        }
                    }
                }
                .padding()
            }
            .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
            .cornerRadius(DesignSystem.BorderRadius.medium)
            .padding(.horizontal)
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Notifications")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal)
            
                    NavigationLink(destination: NotificationSettingsView()) {
                        HStack {
                            Image(systemName: "bell.fill")
                                .foregroundColor(.red)
                    
                            Text("Notifications")
                        .foregroundColor(DesignSystem.Colors.primaryText)
                    
                            Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                        .font(.caption)
                }
                .padding()
                .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                .cornerRadius(DesignSystem.BorderRadius.medium)
            }
            .padding(.horizontal)
        }
    }
    
    private var loggingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("Logging")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal)
            
            VStack(spacing: DesignSystem.Spacing.s) {
                NavigationLink(destination: LogViewerView()) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        Text("View Logs")
                            .font(.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(.caption)
                    }
                    .padding()
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
                
                Toggle(isOn: $enableDetailedLogging) {
                        HStack {
                        Image(systemName: "list.bullet.rectangle")
                            .foregroundColor(.orange)
                                .font(.title3)
                            
                        Text("Detailed Logging")
                                .font(.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
                .onChange(of: enableDetailedLogging) {
                    Logger.info("Detailed logging set to: \(enableDetailedLogging)", category: .settings)
                    UserDefaults.standard.set(enableDetailedLogging, forKey: "enableDetailedLogging")
                }
                .padding()
                .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                .cornerRadius(DesignSystem.BorderRadius.medium)
            }
            .padding(.horizontal)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
            Text("About")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.secondaryText)
                .padding(.horizontal)
            
            VStack(spacing: DesignSystem.Spacing.s) {
                    NavigationLink(destination: AboutView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .font(.title3)
                            
                            Text("About")
                                .font(.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(.caption)
                    }
                    .padding()
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    }
                    
                    NavigationLink(destination: PrivacyPolicyView()) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(DesignSystem.Colors.primaryAction)
                                .font(.title3)
                            
                            Text("Privacy Policy")
                                .font(.body)
                            .foregroundColor(DesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .font(.caption)
                    }
                    .padding()
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Reset onboarding section
    private var resetOnboardingSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.s) {
                    Button(action: {
                Logger.info("Reset onboarding button tapped", category: .settings)
                // Show confirmation dialog before resetting
                showResetConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                                .foregroundColor(.red)
                                .font(.title3)
                            
                            Text("Reset Onboarding")
                                .foregroundColor(.red)
                                .font(.body)
                    
                    Spacer()
                }
                .padding()
                .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                .cornerRadius(DesignSystem.BorderRadius.medium)
                .padding(.horizontal)
            }
            .confirmationDialog("Reset Onboarding?", isPresented: $showResetConfirmation, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    Logger.info("Confirmed reset onboarding", category: .settings)
                    userSettings.resetOnboarding()
                    
                    // Post notification to inform the app that onboarding has been reset
                    NotificationCenter.default.post(name: NSNotification.Name("OnboardingReset"), object: nil)
                }
                Button("Cancel", role: .cancel) {
                    Logger.info("Cancelled reset onboarding", category: .settings)
                }
            } message: {
                Text("This will reset the onboarding experience. You'll need to restart the app to see the onboarding screens again.")
            }
        }
    }
}

/// View for viewing application logs
struct LogViewerView: View {
    @State private var logs: [String] = []
    @State private var selectedCategory: Logger.Category?
    @State private var selectedLevel: Logger.Level?
    @State private var searchText: String = ""
    @State private var isLoading = false
    @State private var showingShareSheet = false
    
    var body: some View {
        ZStack {
            // Premium animated background
            PremiumBackground()
            
            VStack {
                // Filter controls
                HStack {
                    Picker("Category", selection: $selectedCategory) {
                        Text("All").tag(nil as Logger.Category?)
                        ForEach(Logger.Category.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as Logger.Category?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    Picker("Level", selection: $selectedLevel) {
                        Text("All").tag(nil as Logger.Level?)
                        ForEach(Logger.Level.allCases, id: \.self) { level in
                            Text(level.rawValue).tag(level as Logger.Level?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                .cornerRadius(DesignSystem.BorderRadius.medium)
                .padding(.top)
                
                // Search field
                TextField("Search logs", text: $searchText)
                    .padding()
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .padding(.horizontal)
                
                // Log list
                if isLoading {
                    ProgressView("Loading logs...")
                        .padding()
                        .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                        .cornerRadius(DesignSystem.BorderRadius.medium)
                        .padding()
                } else if logs.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                        
                        Text("No logs found")
                            .font(DesignSystem.Typography.title3)
                        
                        Text("Logs will appear here as you use the app")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    .padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(filteredLogs, id: \.self) { log in
                                Text(log)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(nil)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                                    .cornerRadius(DesignSystem.BorderRadius.medium)
                            }
                        }
                        .padding()
                    }
                }
                
                // Actions
                HStack {
                    Button(action: {
                        Logger.info("Refreshing logs", category: .settings)
                        loadLogs()
                    }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        Logger.info("Sharing logs", category: .settings)
                        shareLogFile()
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                    
                    Spacer()
                    
                    Button(action: {
                        Logger.warning("Clearing logs", category: .settings)
                        clearLogs()
                    }) {
                        Label("Clear", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(.red)
                    .background(DesignSystem.CardStyle.glass.backgroundView(cornerRadius: DesignSystem.BorderRadius.medium))
                    .cornerRadius(DesignSystem.BorderRadius.medium)
                }
                .padding()
            }
        }
        .navigationTitle("Logs")
        .onAppear {
            Logger.info("LogViewerView appeared", category: .settings)
            loadLogs()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let logFileURL = Logger.getLogFileURL() {
                ShareSheet(activityItems: [logFileURL])
            }
        }
        .alert("Clear Logs", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                performClearLogs()
            }
        } message: {
            Text("Are you sure you want to clear all logs? This action cannot be undone.")
        }
    }
    
    @State private var showingClearAlert = false
    
    private var filteredLogs: [String] {
        logs.filter { log in
            let categoryMatch = selectedCategory == nil || log.contains("[\(selectedCategory!.rawValue)]")
            let levelMatch = selectedLevel == nil || log.contains("[\(selectedLevel!.rawValue)]")
            let searchMatch = searchText.isEmpty || log.localizedCaseInsensitiveContains(searchText)
            
            return categoryMatch && levelMatch && searchMatch
        }
    }
    
    private func loadLogs() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let loadedLogs = Logger.readLogs()
            
            DispatchQueue.main.async {
                logs = loadedLogs
                isLoading = false
            }
        }
    }
    
    private func clearLogs() {
        showingClearAlert = true
    }
    
    private func performClearLogs() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            Logger.clearLogs()
            
            DispatchQueue.main.async {
                logs = []
                isLoading = false
            }
        }
    }
    
    private func shareLogFile() {
        showingShareSheet = true
    }
}

// Add Category and Level as CaseIterable for the pickers
extension Logger.Category {
    static var allCases: [Logger.Category] = [.app, .challenges, .tasks, .photos, .progress, .settings, .camera, .network, .database, .ui]
}

extension Logger.Level: CaseIterable {
    static var allCases: [Logger.Level] = [.debug, .info, .warning, .error, .critical]
}

/// View for editing user profile
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var userSettings: UserSettings
    
    let user: User
    
    @State private var name: String
    @State private var email: String
    @State private var heightCm: Double?
    @State private var weightKg: Double?
    
    init(user: User) {
        self.user = user
        _name = State(initialValue: user.name)
        _email = State(initialValue: user.email ?? "")
        _heightCm = State(initialValue: user.heightCm)
        _weightKg = State(initialValue: user.weightKg)
        
        Logger.debug("EditProfileView initialized for user: \(user.name)", category: .settings)
    }
    
    var body: some View {
        Form {
            Section(header: Text("Basic Info")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
            
            Section(header: Text("Physical Info")) {
                HStack {
                    Text("Height")
                    Spacer()
                    TextField("Height (cm)", value: $heightCm, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("cm")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Text("Weight")
                    Spacer()
                    TextField("Weight (kg)", value: $weightKg, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                    Text("kg")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Section {
                Button("Save Changes") {
                    Logger.info("Save profile changes button tapped", category: .settings)
                    saveChanges()
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundColor(DesignSystem.Colors.primaryAction)
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Logger.info("EditProfileView appeared for user: \(user.name)", category: .settings)
        }
    }
    
    /// Saves changes to the user profile
    private func saveChanges() {
        Logger.info("Saving profile changes for user: \(user.name)", category: .settings)
        updateUserProfile(user: user, name: name, email: email, heightCm: heightCm ?? 0, weightKg: weightKg ?? 0)
    }
    
    /// Updates the user profile with the provided information
    /// - Parameters:
    ///   - user: The user to update
    ///   - name: The user's name
    ///   - email: The user's email
    ///   - heightCm: The user's height in centimeters
    ///   - weightKg: The user's weight in kilograms
    private func updateUserProfile(user: User, name: String, email: String, heightCm: Double, weightKg: Double) {
        Logger.debug("Updating user profile - Name: \(name), Email: \(email), Height: \(heightCm)cm, Weight: \(weightKg)kg", category: .settings)
        
        user.name = name
        user.email = email.isEmpty ? nil : email
        user.heightCm = heightCm
        user.weightKg = weightKg
        user.updatedAt = Date()
        
        // Update appearance preference if needed
        if let appearance = self.userSettings.selectedAppearance.rawValue as String? {
            user.updateAppearancePreference(appearance)
        }
        
        do {
            try modelContext.save()
            Logger.info("User profile updated successfully", category: .settings)
        } catch {
            Logger.error("Failed to update user profile: \(error.localizedDescription)", category: .settings)
        }
    }
}

/// View for data management
struct DataManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var challenges: [Challenge]
    @Query private var dailyTasks: [DailyTask]
    @Query private var photos: [ProgressPhoto]
    
    @State private var showingDeleteConfirmation = false
    @State private var showingExportOptions = false
    @State private var showingImportOptions = false
    
    var body: some View {
        List {
            Section(header: Text("Statistics")) {
                HStack {
                    Text("Challenges")
                    Spacer()
                    Text("\(challenges.count)")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Text("Daily Tasks")
                    Spacer()
                    Text("\(dailyTasks.count)")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Text("Progress Photos")
                    Spacer()
                    Text("\(photos.count)")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
            
            Section(header: Text("Actions")) {
                Button(action: {
                    Logger.info("Export data button tapped", category: .settings)
                    showingExportOptions = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                        Text("Export Data")
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
                
                Button(action: {
                    Logger.info("Import data button tapped", category: .settings)
                    showingImportOptions = true
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                        Text("Import Data")
                            .foregroundColor(DesignSystem.Colors.primaryText)
                    }
                }
                
                Button(action: {
                    Logger.warning("Delete all data button tapped", category: .settings)
                    showingDeleteConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                        Text("Delete All Data")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("Data Management")
        .alert("Delete All Data", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                Logger.info("Delete all data cancelled", category: .settings)
            }
            Button("Delete", role: .destructive) {
                Logger.warning("Delete all data confirmed", category: .settings)
                deleteAllData()
            }
        } message: {
            Text("Are you sure you want to delete all your data? This action cannot be undone.")
        }
        .alert("Export Data", isPresented: $showingExportOptions) {
            Button("Cancel", role: .cancel) {}
            Button("Export") {
                Logger.info("Export data action triggered", category: .settings)
                // Export functionality would be implemented here
            }
        } message: {
            Text("This feature is not yet implemented.")
        }
        .alert("Import Data", isPresented: $showingImportOptions) {
            Button("Cancel", role: .cancel) {}
            Button("Import") {
                Logger.info("Import data action triggered", category: .settings)
                // Import functionality would be implemented here
            }
        } message: {
            Text("This feature is not yet implemented.")
        }
        .onAppear {
            Logger.info("DataManagementView appeared", category: .settings)
        }
    }
    
    private func deleteAllData() {
        Logger.warning("Deleting all app data", category: .settings)
        
        // Delete all photos
        for photo in photos {
            let photoService = ProgressPhotoService()
            let success = photoService.deletePhoto(at: photo.fileURL)
            Logger.debug("Deleting photo at \(photo.fileURL.lastPathComponent): \(success ? "success" : "failed")", category: .settings)
            modelContext.delete(photo)
        }
        
        // Delete all daily tasks
        for task in dailyTasks {
            Logger.debug("Deleting daily task: \(task.title)", category: .settings)
            modelContext.delete(task)
        }
        
        // Delete all challenges
        for challenge in challenges {
            Logger.debug("Deleting challenge: \(challenge.name)", category: .settings)
            modelContext.delete(challenge)
        }
        
        do {
            try modelContext.save()
            Logger.info("All data deleted successfully", category: .settings)
        } catch {
            Logger.error("Failed to delete all data: \(error.localizedDescription)", category: .settings)
        }
    }
}

/// View for about information
struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: DesignSystem.Spacing.m) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 60))
                            .foregroundColor(DesignSystem.Colors.primaryAction)
                        
                        Text("Challenge Tracker")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Version 1.0.0")
                            .font(.subheadline)
                            .foregroundColor(DesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                }
                .padding()
            }
            
            Section(header: Text("Description")) {
                Text("Challenge Tracker is a premium fitness challenge app designed to help you transform your life through consistent habit building. Track your progress, stay motivated, and achieve your goals.")
                    .font(.body)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                    .padding(.vertical, 8)
            }
            
            Section(header: Text("Credits")) {
                HStack {
                    Text("Developer")
                    Spacer()
                    Text("Sanchay Gumber")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Text("Design")
                    Spacer()
                    Text("Sanchay Gumber")
                        .foregroundColor(DesignSystem.Colors.secondaryText)
                }
            }
        }
        .navigationTitle("About")
        .onAppear {
            Logger.info("AboutView appeared", category: .settings)
        }
    }
}

/// View for privacy policy
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.l) {
                Text("Privacy Policy")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.bottom, DesignSystem.Spacing.s)
                
                Text("Last updated: \(Date(), formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(DesignSystem.Colors.secondaryText)
                
                Text("Your privacy is important to us. This Privacy Policy explains how we collect, use, and protect your personal information when you use our app.")
                    .font(.body)
                
                Text("Data Collection")
                    .font(.headline)
                    .padding(.top, DesignSystem.Spacing.m)
                
                Text("All data is stored locally on your device. We do not collect or transmit any personal information to external servers.")
                    .font(.body)
                
                Text("Data Storage")
                    .font(.headline)
                    .padding(.top, DesignSystem.Spacing.m)
                
                Text("Your challenge data, progress photos, and settings are stored securely on your device. You can delete this data at any time through the app's settings.")
                    .font(.body)
                
                Text("Permissions")
                    .font(.headline)
                    .padding(.top, DesignSystem.Spacing.m)
                
                Text("The app may request access to your camera for progress photos and notifications for reminders. These permissions are optional and can be managed through your device settings.")
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .onAppear {
            Logger.info("PrivacyPolicyView appeared", category: .settings)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: User.self, inMemory: true)
        .environmentObject(UserSettings())
} 
