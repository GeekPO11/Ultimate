//
//  UltimateApp.swift
//  Ultimate
//
//  Created by Sanchay Gumber on 2/28/25.
//

import SwiftUI
import SwiftData
import UserNotifications
import HealthKit
import os.log
import _Concurrency

@main
struct UltimateApp: App {
    @StateObject private var userSettings = UserSettings()
    @StateObject private var notificationManager: NotificationManager = NotificationManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var modelContainer: ModelContainer?
    @StateObject private var dataMigrationService = DataMigrationService.shared
    @StateObject private var enhancedMigrationService = EnhancedDataMigrationService.shared
    @State private var hasRequestedNotificationPermission = false
    @State private var hasRequestedHealthKitPermission = false
    
    // Define model types statically to avoid type inference
    private static let modelTypes: [any PersistentModel.Type] = [
        Challenge.self,
        Task.self,
        DailyTask.self,
        ProgressPhoto.self,
        User.self
    ]
    
    init() {
        print("UltimateApp: Initializing...")
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Reset badge count on launch
        UNUserNotificationCenter.current().setBadgeCount(0)
        
        print("UltimateApp: Initialization complete")
    }
    
    var body: some Scene {
        WindowGroup {
            if modelContainer == nil {
                // Show loading view while container is being created
                ProgressView("Setting up...")
                    .onAppear {
                        setupModelContainer()
                    }
            } else if !hasCompletedOnboarding {
                OnboardingView()
                    .modelContainer(modelContainer!)
                    .environmentObject(userSettings)
            } else {
                MainTabView()
                    .modelContainer(modelContainer!)
                    .environmentObject(userSettings)
                    .onAppear {
                        // Request notifications permission
                        if !hasRequestedNotificationPermission {
                            NotificationManager.shared.requestAuthorization()
                            hasRequestedNotificationPermission = true
                        }
                        
                        // Set up HealthKit integration
                        if !hasRequestedHealthKitPermission {
                            setupHealthKitIntegration()
                        }
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .active {
                            // Refresh health data when app becomes active
                            DailyTaskManager.shared.checkAndUpdateWorkoutTasks()
                        }
                    }
                    .onChange(of: dataMigrationService.isMigrationComplete) { _, _ in
                        // Refresh data after migration if needed
                    }
            }
        }
    }
    
    // Setup HealthKit integration
    private func setupHealthKitIntegration() {
        // Set model context in DailyTaskManager
        if let modelContext = modelContainer?.mainContext {
            DailyTaskManager.shared.setModelContext(modelContext)
            
            // First check if HealthKit is available without requesting permissions
            if !DailyTaskManager.shared.checkHealthKitStatus() {
                Logger.info("HealthKit integration available but not authorized yet", category: .healthKit)
            }
            
            // Request HealthKit authorization with retry logic
            DailyTaskManager.shared.requestHealthKitAuthorization { success in
                if success {
                    Logger.info("HealthKit authorization successful", category: .healthKit)
                    self.hasRequestedHealthKitPermission = true
                    
                    // Only start tracking if authorized
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        // Delay by 1 second to ensure everything is initialized
                        DailyTaskManager.shared.startWorkoutTrackingTimer()
                    }
                } else {
                    Logger.warning("HealthKit authorization denied or unavailable - app will continue without fitness tracking", category: .healthKit)
                    // We still mark as requested even though permission was denied
                    self.hasRequestedHealthKitPermission = true
                }
            }
        } else {
            Logger.error("Model context not available for HealthKit integration", category: .database)
        }
    }
    
    private func setupModelContainer() {
        do {
            // Create a schema with all model types
            let schema = Schema([
                Challenge.self,
                Task.self,
                DailyTask.self,
                ProgressPhoto.self,
                User.self
            ])
            
            // Create a configuration with migration options
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            // Try to create the container with the configuration
            do {
                let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
                
                // Set up migration handler for the container's context
                let context = container.mainContext
                
                // Perform explicit stabilization of all models, especially Task
                try populateTimeOfDayValues(context: context)
                
                // Then perform migration checks
                _Concurrency.Task {
                    await enhancedMigrationService.performMigration(modelContext: context)
                }
                
                // Set the container
                self.modelContainer = container
                Logger.info("Model container created successfully", category: .database)
            } catch {
                // First attempt failed, try to recover
                Logger.error("Failed to create model container: \(error.localizedDescription)", category: .database)
                throw error // Re-throw to be caught by outer catch block
            }
        } catch {
            Logger.error("Failed to create model container: \(error.localizedDescription)", category: .database)
            
            // Try to delete the store and create a new one
            Logger.warning("Attempting to delete and recreate the persistent store", category: .database)
            
            do {
                // Try to delete the persistent store files manually
                try deletePersistentStore()
            } catch {
                Logger.warning("Failed to delete persistent store: \(error.localizedDescription)", category: .database)
            }
            
            // Create a basic container after attempting to delete the store
            let schema = Schema([
                Challenge.self,
                Task.self,
                DailyTask.self,
                ProgressPhoto.self,
                User.self
            ])
            
            // Try with a simpler configuration
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )
            
            do {
                self.modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                Logger.info("Created new model container after deleting store", category: .database)
                
                // After successful creation, perform migration
                if let container = self.modelContainer {
                    do {
                        try populateTimeOfDayValues(context: container.mainContext)
                    } catch {
                        Logger.warning("Failed to populate timeOfDay values: \(error.localizedDescription)", category: .database)
                    }
                    _Concurrency.Task {
                        await enhancedMigrationService.performMigration(modelContext: container.mainContext)
                    }
                }
            } catch {
                Logger.error("Failed to create model container even after deleting store: \(error.localizedDescription)", category: .database)
                
                // Last resort: try in-memory only
                do {
                    let inMemoryConfig = ModelConfiguration(
                        schema: schema,
                        isStoredInMemoryOnly: true,
                        allowsSave: true
                    )
                    self.modelContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                    Logger.warning("Created in-memory model container as last resort", category: .database)
                } catch {
                    Logger.error("All attempts to create model container failed: \(error.localizedDescription)", category: .database)
                }
            }
        }
    }
    
    // Helper method to ensure all Task instances have valid timeOfDay values
    private func populateTimeOfDayValues(context: ModelContext) throws {
        Logger.info("Ensuring all Task instances have valid timeOfDay values", category: .database)
        
        // Fetch all Tasks that might not have proper timeOfDay values
        let descriptor = FetchDescriptor<Task>()
        let tasks = try context.fetch(descriptor)
        
        var updatedCount = 0
        
        // Process each task and check if timeOfDay needs initialization
        for task in tasks {
            // Check if timeOfDay is properly set, if not, set it to a default value
            // This is a safer approach than force-accessing the property
            if task.scheduledTime == nil && task.type == .workout {
                // For workout tasks without a scheduled time, default to anytime
                task.timeOfDay = .anytime
                updatedCount += 1
            } else if task.timeOfDay == .anytime && task.scheduledTime != nil {
                // For tasks with scheduled times, set appropriate timeOfDay
                let calendar = Calendar.current
                let hour = calendar.component(.hour, from: task.scheduledTime!)
                
                if hour < 12 {
                    task.timeOfDay = .morning
                } else {
                    task.timeOfDay = .evening
                }
                updatedCount += 1
            }
        }
        
        // Save changes if any tasks were updated
        if updatedCount > 0 {
            Logger.info("Updated timeOfDay for \(updatedCount) tasks", category: .database)
            try context.save()
        } else {
            Logger.info("All tasks already have proper timeOfDay values", category: .database)
        }
    }
    
    // Helper method to delete the persistent store files
    private func deletePersistentStore() throws {
        let fileManager = FileManager.default
        
        // Get all possible locations where SwiftData might store files
        let locations = [
            try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
            try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false),
            try fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        ]
        
        var deletedAny = false
        var lastError: Error? = nil
        
        // Check each location for SwiftData stores
        for baseURL in locations {
            // Common SwiftData store names/patterns
            let storePatterns = ["default.store", "*.sqlite", "*.sqlite-shm", "*.sqlite-wal"]
            
            for pattern in storePatterns {
                do {
                    // Find all files matching the pattern
                    let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
                    let directoryEnumerator = fileManager.enumerator(
                        at: baseURL,
                        includingPropertiesForKeys: resourceKeys,
                        options: [.skipsHiddenFiles],
                        errorHandler: nil
                    )
                    
                    guard let enumerator = directoryEnumerator else { continue }
                    
                    for case let fileURL as URL in enumerator {
                        // Check if the file matches our pattern
                        if fileURL.lastPathComponent.contains(pattern.replacingOccurrences(of: "*", with: "")) ||
                           (pattern == "default.store" && fileURL.lastPathComponent == pattern) {
                            do {
                                try fileManager.removeItem(at: fileURL)
                                Logger.info("Deleted SwiftData file: \(fileURL.path)", category: .database)
                                deletedAny = true
                            } catch {
                                Logger.warning("Failed to delete file \(fileURL.path): \(error.localizedDescription)", category: .database)
                                lastError = error
                            }
                        }
                    }
                } catch {
                    Logger.warning("Error enumerating directory \(baseURL.path): \(error.localizedDescription)", category: .database)
                    lastError = error
                }
            }
        }
        
        // If we didn't delete anything and have an error, throw it
        if !deletedAny && lastError != nil {
            throw lastError!
        }
        
        // If we deleted at least one file, consider it a success
        if deletedAny {
            Logger.info("Successfully deleted one or more persistent store files", category: .database)
        } else {
            Logger.warning("No persistent store files found to delete", category: .database)
        }
    }
}

/// Delegate for handling notification responses
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    private override init() {
        super.init()
    }
    
    /// Called when a notification is received while the app is in the foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when the user responds to a notification
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle the notification response
        NotificationManager.shared.handleNotificationResponse(response, completionHandler: completionHandler)
    }
}
